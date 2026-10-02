import com.sun.net.httpserver.HttpExchange;

/**
 * CORS utility for BongoJatra backend.
 * Adds permissive CORS headers to every HTTP response.
 */
public class CorsUtil {

    public static void addCorsHeaders(HttpExchange exchange) {
        exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        exchange.getResponseHeaders().set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        exchange.getResponseHeaders().set("Access-Control-Allow-Headers", "Content-Type, Authorization");
        exchange.getResponseHeaders().set("Access-Control-Max-Age", "86400");
    }
}
