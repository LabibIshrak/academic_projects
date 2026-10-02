import java.util.*;
import java.time.Instant;

/**
 * In-memory booking store for BongoJatra.
 * Tracks bookings per user and seat availability per transport option.
 */
public class BookingStore {

    public static class Booking {
        public String bookingId;
        public String optionId;
        public String transportName;
        public String type;
        public String origin;
        public String destination;
        public String seatId;
        public String seatClass;
        public String coachId;
        public int price;
        public String departureTime;
        public String arrivalTime;
        public String operator;
        public String paymentMethod;
        public String status; // CONFIRMED or CANCELLED
        public String bookedAt;
        public String journeyDate;

        public String getPrefix() {
            String dateSuffix = journeyDate != null ? "_" + journeyDate : "";
            if ("TRAIN".equals(type) && seatClass != null && coachId != null) {
                return optionId + "_" + seatClass + "_" + coachId + dateSuffix;
            }
            return optionId + dateSuffix;
        }

        public String toJson() {
            StringBuilder sb = new StringBuilder("{");
            sb.append("\"bookingId\":\"").append(bookingId).append("\",");
            sb.append("\"optionId\":\"").append(optionId).append("\",");
            sb.append("\"transportName\":\"").append(JsonUtil.escapeString(transportName)).append("\",");
            sb.append("\"type\":\"").append(type).append("\",");
            sb.append("\"origin\":\"").append(origin).append("\",");
            sb.append("\"destination\":\"").append(destination).append("\",");
            sb.append("\"seatId\":\"").append(seatId).append("\",");
            sb.append("\"seatClass\":\"").append(seatClass).append("\",");
            sb.append("\"coachId\":\"").append(coachId).append("\",");
            sb.append("\"price\":").append(price).append(",");
            sb.append("\"departureTime\":\"").append(departureTime).append("\",");
            sb.append("\"arrivalTime\":\"").append(arrivalTime).append("\",");
            sb.append("\"operator\":\"").append(JsonUtil.escapeString(operator)).append("\",");
            sb.append("\"paymentMethod\":\"").append(paymentMethod).append("\",");
            sb.append("\"status\":\"").append(status).append("\",");
            sb.append("\"bookedAt\":\"").append(bookedAt).append("\",");
            sb.append("\"journeyDate\":\"").append(journeyDate).append("\"");
            sb.append("}");
            return sb.toString();
        }
    }

    // email -> list of bookings
    private static final HashMap<String, List<Booking>> bookings = new HashMap<>();
    // prefix -> set of taken seat IDs
    private static final HashMap<String, Set<String>> takenSeats = new HashMap<>();

    private static final Random random = new Random();
    private static final String CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    static {
        // Pre-book seats to simulate existing passengers for Pabna routes
        
        // Buses
        String[] busOptions = {
            "PAB-DHK-B1","PAB-DHK-B2","PAB-DHK-B3","DHK-PAB-B1",
            "PAB-RAJ-B1","PAB-RAJ-B2","RAJ-PAB-B1"
        };
        String[] busPrebooked = {"1A","2C","3B","3D","4A","5C","6B","6D","7A","8C","9B","10D"};
        for (String opt : busOptions) {
            Set<String> set = new HashSet<>(Arrays.asList(busPrebooked));
            takenSeats.put(opt, set);
        }

        // Trains (use prefix: optionId_classType_coachId)
        String[] trainOptions = {
            "PAB-DHK-T1_SNIGDHA_Ka", "PAB-DHK-T1_SHOBHON_Ka", "PAB-DHK-T1_AC_BERTH_Ka",
            "DHK-PAB-T1_SNIGDHA_Ka"
        };
        String[] trainSnigdhaPrebooked = {"1W1","1M2","2W2","3M1","3M2","4W1","5W2","5M1","6W1","6M2"};
        String[] trainShobhonPrebooked = {"1A","2C","3B","3D","3E","4A","5C","6B","6D","7A","8C"};
        String[] trainACBerthPrebooked = {"1L","1U","3L","5U","8L"};

        takenSeats.put("PAB-DHK-T1_SNIGDHA_Ka", new HashSet<>(Arrays.asList(trainSnigdhaPrebooked)));
        takenSeats.put("PAB-DHK-T1_SHOBHON_Ka", new HashSet<>(Arrays.asList(trainShobhonPrebooked)));
        takenSeats.put("PAB-DHK-T1_AC_BERTH_Ka", new HashSet<>(Arrays.asList(trainACBerthPrebooked)));
        takenSeats.put("DHK-PAB-T1_SNIGDHA_Ka", new HashSet<>(Arrays.asList(trainSnigdhaPrebooked)));
        
        // Train AC First
        takenSeats.put("PAB-DHK-T3_AC_FIRST_Ka", new HashSet<>(Arrays.asList("C2-1L", "C2-1U", "C2-2L", "C2-2U", "C5-1L")));

        // Launch Deck
        String[] deckPrebooked = {"D3","D7","D12","D18","D22","D28","D33","D37","D42","D46"};
        takenSeats.put("PAB-KHL-L1", new HashSet<>(Arrays.asList(deckPrebooked)));
        takenSeats.put("PAB-BAR-L1", new HashSet<>(Arrays.asList(deckPrebooked)));

        // Launch Cabin
        String[] cabinPrebooked = {"C3","C5","C8"};
        takenSeats.put("PAB-KHL-L2", new HashSet<>(Arrays.asList(cabinPrebooked)));
        takenSeats.put("PAB-BAR-L2", new HashSet<>(Arrays.asList(cabinPrebooked)));
    }

    public static String generateBookingId() {
        StringBuilder sb = new StringBuilder("BJ-");
        for (int i = 0; i < 6; i++) {
            sb.append(CHARS.charAt(random.nextInt(CHARS.length())));
        }
        return sb.toString();
    }

    public static synchronized String addBooking(String email, Booking booking) {
        booking.bookingId = generateBookingId();
        booking.status = "CONFIRMED";
        booking.bookedAt = Instant.now().toString();
        bookings.computeIfAbsent(email, k -> new ArrayList<>()).add(booking);
        markSeatTaken(booking.getPrefix(), booking.seatId);
        return booking.bookingId;
    }

    public static List<Booking> getBookings(String email) {
        return bookings.getOrDefault(email, new ArrayList<>());
    }

    public static synchronized boolean cancelBooking(String email, String bookingId) {
        List<Booking> list = bookings.get(email);
        if (list == null) return false;
        for (Booking b : list) {
            if (b.bookingId.equals(bookingId) && "CONFIRMED".equals(b.status)) {
                b.status = "CANCELLED";
                freeSeat(b.getPrefix(), b.seatId);
                return true;
            }
        }
        return false;
    }

    public static boolean isSeatTaken(String prefix, String seatId) {
        Set<String> set = takenSeats.get(prefix);
        return set != null && set.contains(seatId);
    }

    public static synchronized void markSeatTaken(String prefix, String seatId) {
        takenSeats.computeIfAbsent(prefix, k -> new HashSet<>()).add(seatId);
    }

    public static synchronized void freeSeat(String prefix, String seatId) {
        Set<String> set = takenSeats.get(prefix);
        if (set != null) set.remove(seatId);
    }

    public static int getAvailableCount(String prefix, int totalSeats) {
        Set<String> set = takenSeats.get(prefix);
        if (set == null) return totalSeats;
        return totalSeats - set.size();
    }
}
