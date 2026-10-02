import java.util.HashMap;
import java.util.Base64;
import java.time.Instant;

/**
 * In-memory user store for BongoJatra.
 * Token = Base64(email) — fine for a university prototype.
 */
public class UserStore {

    public static class User {
        public String name;
        public String email;
        public String createdAt;

        public User(String name, String email) {
            this.name = name;
            this.email = email;
            this.createdAt = Instant.now().toString();
        }
    }

    private static final HashMap<String, User> users = new HashMap<>();

    public static User findOrCreate(String email, String name) {
        return users.computeIfAbsent(email, e -> new User(name, e));
    }

    public static String generateToken(String email) {
        return Base64.getEncoder().encodeToString(email.getBytes());
    }

    public static String getEmailFromToken(String token) {
        try {
            return new String(Base64.getDecoder().decode(token));
        } catch (Exception e) {
            return null;
        }
    }

    public static String getByToken(String token) {
        return getEmailFromToken(token);
    }

    public static User getByEmail(String email) {
        return users.get(email);
    }
}
