import com.sun.net.httpserver.HttpExchange;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

/**
 * JSON utility helpers for BongoJatra backend.
 * Manual JSON parsing and building — no external libraries.
 */
public class JsonUtil {

    /** Extract a string value for "key":"value" from a JSON string. */
    public static String parseField(String json, String key) {
        if (json == null) return null;
        String[] patterns = {
            "\"" + key + "\":\"",
            "\"" + key + "\": \"",
            "\"" + key + "\" : \""
        };
        for (String p : patterns) {
            int s = json.indexOf(p);
            if (s >= 0) {
                s += p.length();
                int e = s;
                while (e < json.length()) {
                    if (json.charAt(e) == '"' && (e == 0 || json.charAt(e - 1) != '\\')) break;
                    e++;
                }
                if (e < json.length()) return json.substring(s, e).trim();
            }
        }
        return null;
    }

    /** Escape a string for safe JSON embedding. */
    public static String escapeString(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "").replace("\t", "\\t");
    }

    /** Read the full request body as a string. */
    public static String readBody(HttpExchange exchange) throws Exception {
        InputStream is = exchange.getRequestBody();
        String body = new String(is.readAllBytes(), StandardCharsets.UTF_8);
        is.close();
        return body;
    }
}
