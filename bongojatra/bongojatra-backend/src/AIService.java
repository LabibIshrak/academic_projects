import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;

/**
 * Groq AI integration for BongoJatra.
 * Calls llama-3.1-8b-instant for transport recommendations.
 * Falls back silently if the API call fails.
 */
public class AIService {

    private static final String GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
    private static final String MODEL = "llama-3.1-8b-instant";

    public static String getSuggestion(List<TransportData.TransportOption> options,
                                       String preference, String apiKey) {
        if (apiKey == null || apiKey.isBlank()) {
            System.out.println("[AI] No GROQ_API_KEY, using fallback.");
            return buildFallback(options, preference);
        }
        try {
            StringBuilder optLines = new StringBuilder();
            for (TransportData.TransportOption opt : options) {
                optLines.append(opt.toPromptLine()).append("\\n");
            }
            String origin = options.get(0).origin;
            String dest = options.get(0).destination;

            String prompt = "You are a transport advisor for BongoJatra, Bangladesh transport app. "
                + "Passenger: " + origin + " to " + dest + ". Preference: " + preference + ". "
                + "FASTEST=least time, CHEAPEST=lowest price, COMFORTABLE=most amenities, SCENIC=prefer water/launch routes. "
                + "Options:\\n" + optLines
                + "Reply ONLY with valid JSON, no markdown, no explanation:\\n"
                + "{\\n  \\\"recommendation\\\": \\\"one friendly sentence\\\",\\n"
                + "  \\\"recommendedId\\\": \\\"exact id from list\\\",\\n"
                + "  \\\"reason\\\": \\\"two sentences why this fits preference\\\",\\n"
                + "  \\\"tip\\\": \\\"one practical travel tip\\\"\\n}";

            String escaped = prompt.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "").replace("\t", "\\t");

            String body = "{\"model\":\"" + MODEL + "\","
                + "\"messages\":[{\"role\":\"user\",\"content\":\"" + escaped + "\"}],"
                + "\"max_tokens\":400}";

            HttpClient client = HttpClient.newHttpClient();
            HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(GROQ_URL))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + apiKey)
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

            HttpResponse<String> resp = client.send(req, HttpResponse.BodyHandlers.ofString());
            System.out.println("[AI] Groq status: " + resp.statusCode());

            if (resp.statusCode() != 200) return buildFallback(options, preference);

            String content = extractField(resp.body(), "content");
            if (content == null || content.isBlank()) return buildFallback(options, preference);

            content = content.replace("```json", "").replace("```", "").trim();
            content = content.replace("\\n", "\n").replace("\\\"", "\"");

            String rec = extractField(content, "recommendation");
            String recId = extractField(content, "recommendedId");
            String reason = extractField(content, "reason");
            String tip = extractField(content, "tip");

            if (rec == null || recId == null) return buildFallback(options, preference);

            boolean valid = false;
            for (TransportData.TransportOption o : options) {
                if (o.id.equals(recId)) { valid = true; break; }
            }
            if (!valid) return buildFallback(options, preference);

            return buildJson(esc(rec), recId, esc(reason != null ? reason : "Best match."),
                esc(tip != null ? tip : "Have a safe journey!"));
        } catch (Exception e) {
            System.out.println("[AI] Error: " + e.getMessage());
            return buildFallback(options, preference);
        }
    }

    private static String buildFallback(List<TransportData.TransportOption> options, String pref) {
        if (options.isEmpty()) return buildJson("No options available.", "", "No transport found.", "Try another route.");

        TransportData.TransportOption pick = options.get(0);
        String reason;

        switch (pref.toUpperCase()) {
            case "FASTEST":
                for (var o : options) if (o.durationMinutes < pick.durationMinutes) pick = o;
                reason = "Shortest travel time at " + pick.durationMinutes + " minutes. Gets you there quickest.";
                break;
            case "CHEAPEST":
                for (var o : options) if (o.price < pick.price) pick = o;
                reason = "Most affordable at \\u09F3" + pick.price + ". Great for budget travelers.";
                break;
            case "COMFORTABLE":
                for (var o : options) if (o.amenities.length > pick.amenities.length) pick = o;
                reason = "Most amenities including " + pick.amenities[0] + ". Travel in comfort!";
                break;
            case "SCENIC":
                TransportData.TransportOption launch = null;
                for (var o : options) if (o.type.equals("LAUNCH")) { launch = o; break; }
                if (launch != null) {
                    pick = launch;
                    reason = "Scenic overnight water journey through Bangladesh rivers. A unique experience!";
                } else {
                    for (var o : options) if (o.durationMinutes < pick.durationMinutes) pick = o;
                    reason = "No scenic water route available. Recommending the fastest option instead.";
                }
                break;
            default:
                reason = "Good balance of price and comfort for your journey.";
        }

        String rec = "We recommend " + pick.name + " by " + pick.operator + " for your journey!";
        String tip = pick.type.equals("LAUNCH")
            ? "Bring warm clothes and essentials for the overnight river journey."
            : "Arrive 30 minutes early to secure your seat.";

        return buildJson(esc(rec), pick.id, esc(reason), esc(tip));
    }

    private static String buildJson(String rec, String id, String reason, String tip) {
        return "{\"recommendation\":\"" + rec + "\",\"recommendedId\":\"" + id
            + "\",\"reason\":\"" + reason + "\",\"tip\":\"" + tip + "\"}";
    }

    static String extractField(String json, String field) {
        if (json == null) return null;
        String[] pats = {"\"" + field + "\":\"", "\"" + field + "\": \"", "\"" + field + "\" : \""};
        for (String p : pats) {
            int s = json.indexOf(p);
            if (s >= 0) {
                s += p.length();
                int e = s;
                while (e < json.length()) {
                    if (json.charAt(e) == '"' && (e == 0 || json.charAt(e - 1) != '\\')) break;
                    e++;
                }
                if (e < json.length()) return json.substring(s, e);
            }
        }
        return null;
    }

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }
}
