import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * BongoJatra Backend Server — Plain Java HttpServer.
 * Endpoints:
 *   POST /api/auth/google       — authenticate / create user
 *   GET  /api/cities             — list cities
 *   POST /api/route/suggest      — get routes + AI suggestion
 *   GET  /api/seats/             — seat map for an option
 *   POST /api/booking/confirm    — confirm a booking
 *   GET  /api/booking/history    — user booking history
 *   POST /api/booking/cancel     — cancel a booking
 */
public class Server {

    private static String GROQ_API_KEY;

    public static void main(String[] args) throws IOException {
        GROQ_API_KEY = System.getenv("GROQ_API_KEY");
        if (GROQ_API_KEY == null || GROQ_API_KEY.isBlank()) {
            System.out.println("[WARN] GROQ_API_KEY not set. AI suggestions will use fallback.");
        } else {
            System.out.println("[OK] GROQ_API_KEY loaded.");
        }

        int port = 8080;
        if (args.length > 0) {
            try { port = Integer.parseInt(args[0]); } catch (NumberFormatException ignored) {}
        }

        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/api/auth/google", Server::handleAuth);
        server.createContext("/api/cities", Server::handleCities);
        server.createContext("/api/route/suggest", Server::handleRouteSuggest);
        server.createContext("/api/seats/", Server::handleSeats);
        server.createContext("/api/booking/confirm", Server::handleBookingConfirm);
        server.createContext("/api/booking/history", Server::handleBookingHistory);
        server.createContext("/api/booking/cancel", Server::handleBookingCancel);

        server.setExecutor(null);
        server.start();
        System.out.println("BongoJatra running on :" + port);
    }

    // ─── Auth ───
    private static void handleAuth(HttpExchange ex) throws IOException {
        CorsUtil.addCorsHeaders(ex);
        if (preflight(ex)) return;
        if (!requireMethod(ex, "POST")) return;
        try {
            String body = JsonUtil.readBody(ex);
            String email = JsonUtil.parseField(body, "email");
            String name = JsonUtil.parseField(body, "name");
            if (email == null || email.isBlank()) { sendJson(ex, 400, "{\"success\":false,\"error\":\"Missing email\"}"); return; }
            if (name == null || name.isBlank()) name = "User";
            UserStore.findOrCreate(email, name);
            String token = UserStore.generateToken(email);
            sendJson(ex, 200, "{\"success\":true,\"token\":\"" + token + "\",\"name\":\""
                + JsonUtil.escapeString(name) + "\",\"email\":\"" + JsonUtil.escapeString(email) + "\"}");
        } catch (Exception e) {
            sendJson(ex, 500, "{\"success\":false,\"error\":\"" + JsonUtil.escapeString(e.getMessage()) + "\"}");
        }
    }

    // ─── Cities ───
    private static void handleCities(HttpExchange ex) throws IOException {
        CorsUtil.addCorsHeaders(ex);
        if (preflight(ex)) return;
        List<String> cities = TransportData.getCities();
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < cities.size(); i++) {
            json.append("\"").append(cities.get(i)).append("\"");
            if (i < cities.size() - 1) json.append(",");
        }
        json.append("]");
        sendJson(ex, 200, json.toString());
    }

    // ─── Route Suggest ───
    private static void handleRouteSuggest(HttpExchange ex) throws IOException {
        CorsUtil.addCorsHeaders(ex);
        if (preflight(ex)) return;
        if (!requireMethod(ex, "POST")) return;
        String email = getAuthEmail(ex);
        if (email == null) { sendJson(ex, 401, "{\"routeFound\":false,\"error\":\"Unauthorized\",\"options\":[],\"aiSuggestion\":null}"); return; }
        try {
            String body = JsonUtil.readBody(ex);
            String origin = JsonUtil.parseField(body, "origin");
            String destination = JsonUtil.parseField(body, "destination");
            String preference = JsonUtil.parseField(body, "preference");
            String travelDate = JsonUtil.parseField(body, "travelDate");
            String preferredTimeSlot = JsonUtil.parseField(body, "preferredTimeSlot");
            if (origin == null || destination == null) {
                sendJson(ex, 400, "{\"routeFound\":false,\"error\":\"Missing origin or destination\"}");
                return;
            }
            if (preference == null || preference.isBlank()) preference = "FASTEST";
            System.out.println("[REQ] " + origin + " -> " + destination + " (" + preference + ") on " + travelDate);

            List<TransportData.TransportOption> options = TransportData.getOptions(origin, destination, preferredTimeSlot, travelDate);
            if (options.isEmpty()) {
                sendJson(ex, 200, "{\"routeFound\":false,\"error\":\"No routes found\",\"options\":[],\"aiSuggestion\":null}");
                return;
            }

            String ai = AIService.getSuggestion(options, preference, GROQ_API_KEY);
            StringBuilder opts = new StringBuilder("[");
            for (int i = 0; i < options.size(); i++) {
                opts.append(options.get(i).toJson());
                if (i < options.size() - 1) opts.append(",");
            }
            opts.append("]");

            String resp = "{\"routeFound\":true,\"origin\":\"" + origin + "\",\"destination\":\"" + destination
                + "\",\"preference\":\"" + preference + "\",\"options\":" + opts + ",\"aiSuggestion\":" + ai + "}";
            sendJson(ex, 200, resp);
        } catch (Exception e) {
            sendJson(ex, 500, "{\"routeFound\":false,\"error\":\"" + JsonUtil.escapeString(e.getMessage()) + "\"}");
        }
    }

    // ─── Seats ───
    private static void handleSeats(HttpExchange ex) throws IOException {
        CorsUtil.addCorsHeaders(ex);
        if (preflight(ex)) return;
        String path = ex.getRequestURI().getPath();
        String params = path.substring("/api/seats/".length());
        if (params.isEmpty()) { sendJson(ex, 400, "{\"error\":\"Missing optionId\"}"); return; }
        
        String[] parts = params.split("/");
        String optionId = parts[0];
        String classType = parts.length > 1 ? parts[1] : null;
        String coachId = parts.length > 2 ? parts[2] : null;

        TransportData.TransportOption opt = TransportData.getById(optionId);
        if (opt == null) { sendJson(ex, 404, "{\"error\":\"Option not found\"}"); return; }
        sendJson(ex, 200, TransportData.getSeatsJson(opt, classType, coachId));
    }

    // ─── Booking Confirm ───
    private static void handleBookingConfirm(HttpExchange ex) throws IOException {
        CorsUtil.addCorsHeaders(ex);
        if (preflight(ex)) return;
        if (!requireMethod(ex, "POST")) return;
        String email = getAuthEmail(ex);
        if (email == null) { sendJson(ex, 401, "{\"success\":false,\"error\":\"Unauthorized\"}"); return; }
        try {
            String body = JsonUtil.readBody(ex);
            String optionId = JsonUtil.parseField(body, "optionId");
            String seatId = JsonUtil.parseField(body, "seatId");
            String classType = JsonUtil.parseField(body, "classType");
            String coachId = JsonUtil.parseField(body, "coachId");
            String paymentMethod = JsonUtil.parseField(body, "paymentMethod");
            String journeyDate = JsonUtil.parseField(body, "journeyDate");
            if (optionId == null || seatId == null) {
                sendJson(ex, 400, "{\"success\":false,\"error\":\"Missing optionId or seatId\"}"); return;
            }
            TransportData.TransportOption opt = TransportData.getById(optionId);
            if (opt == null) { sendJson(ex, 404, "{\"success\":false,\"error\":\"Option not found\"}"); return; }
            
            BookingStore.Booking b = new BookingStore.Booking();
            b.optionId = optionId; b.seatId = seatId;
            b.transportName = opt.name; b.type = opt.type;
            b.origin = opt.origin; b.destination = opt.destination;
            b.seatClass = classType != null ? classType : opt.classType; 
            b.coachId = coachId;
            b.price = opt.price;
            b.departureTime = opt.departureTime; b.arrivalTime = opt.arrivalTime;
            b.operator = opt.operator;
            b.paymentMethod = paymentMethod != null ? paymentMethod : "UNKNOWN";
            b.journeyDate = journeyDate;

            if (BookingStore.isSeatTaken(b.getPrefix(), seatId)) {
                sendJson(ex, 409, "{\"success\":false,\"error\":\"Seat already taken\"}"); return;
            }

            String bookingId = BookingStore.addBooking(email, b);
            System.out.println("[BOOK] " + bookingId + " | " + email + " | " + opt.name + " seat " + seatId);
            sendJson(ex, 200, "{\"success\":true,\"bookingId\":\"" + bookingId
                + "\",\"message\":\"Booking confirmed! Seat " + seatId + " reserved.\"}");
        } catch (Exception e) {
            sendJson(ex, 500, "{\"success\":false,\"error\":\"" + JsonUtil.escapeString(e.getMessage()) + "\"}");
        }
    }

    // ─── Booking History ───
    private static void handleBookingHistory(HttpExchange ex) throws IOException {
        CorsUtil.addCorsHeaders(ex);
        if (preflight(ex)) return;
        String email = getAuthEmail(ex);
        if (email == null) { sendJson(ex, 401, "{\"error\":\"Unauthorized\"}"); return; }
        List<BookingStore.Booking> list = BookingStore.getBookings(email);
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < list.size(); i++) {
            json.append(list.get(i).toJson());
            if (i < list.size() - 1) json.append(",");
        }
        json.append("]");
        sendJson(ex, 200, json.toString());
    }

    // ─── Booking Cancel ───
    private static void handleBookingCancel(HttpExchange ex) throws IOException {
        CorsUtil.addCorsHeaders(ex);
        if (preflight(ex)) return;
        if (!requireMethod(ex, "POST")) return;
        String email = getAuthEmail(ex);
        if (email == null) { sendJson(ex, 401, "{\"success\":false,\"error\":\"Unauthorized\"}"); return; }
        try {
            String body = JsonUtil.readBody(ex);
            String bookingId = JsonUtil.parseField(body, "bookingId");
            if (bookingId == null) { sendJson(ex, 400, "{\"success\":false,\"error\":\"Missing bookingId\"}"); return; }
            boolean ok = BookingStore.cancelBooking(email, bookingId);
            if (ok) {
                System.out.println("[CANCEL] " + bookingId + " by " + email);
                sendJson(ex, 200, "{\"success\":true}");
            } else {
                sendJson(ex, 404, "{\"success\":false,\"error\":\"Booking not found or already cancelled\"}");
            }
        } catch (Exception e) {
            sendJson(ex, 500, "{\"success\":false,\"error\":\"" + JsonUtil.escapeString(e.getMessage()) + "\"}");
        }
    }

    // ─── Helpers ───
    private static boolean preflight(HttpExchange ex) throws IOException {
        if ("OPTIONS".equalsIgnoreCase(ex.getRequestMethod())) {
            ex.sendResponseHeaders(204, -1); return true;
        }
        return false;
    }

    private static boolean requireMethod(HttpExchange ex, String method) throws IOException {
        if (!method.equalsIgnoreCase(ex.getRequestMethod())) {
            sendJson(ex, 405, "{\"error\":\"Method not allowed\"}"); return false;
        }
        return true;
    }

    private static String getAuthEmail(HttpExchange ex) {
        String auth = ex.getRequestHeaders().getFirst("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) return null;
        String token = auth.substring(7).trim();
        return UserStore.getByToken(token);
    }

    private static void sendJson(HttpExchange ex, int status, String json) throws IOException {
        ex.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        ex.sendResponseHeaders(status, bytes.length);
        OutputStream os = ex.getResponseBody();
        os.write(bytes);
        os.close();
    }
}
