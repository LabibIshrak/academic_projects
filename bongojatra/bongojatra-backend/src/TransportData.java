import java.util.ArrayList;
import java.util.List;

/**
 * All mock transport data for BongoJatra.
 * Centered around Pabna routes.
 */
public class TransportData {

    public static class Coach {
        public String coachId;
        public String coachLabel;
        public int totalSeats;
        public String layout;

        public Coach(String coachId, String coachLabel, int totalSeats, String layout) {
            this.coachId = coachId;
            this.coachLabel = coachLabel;
            this.totalSeats = totalSeats;
            this.layout = layout;
        }

        public String toJson(String optionId, String classType) {
            int avail = BookingStore.getAvailableCount(optionId + "_" + classType + "_" + coachId, totalSeats);
            return "{\"coachId\":\"" + coachId + "\",\"coachLabel\":\"" + coachLabel + "\",\"totalSeats\":" + totalSeats + ",\"availableSeats\":" + avail + ",\"layout\":\"" + layout + "\"}";
        }
    }

    public static class TrainClass {
        public String classType;
        public String classLabel;
        public int price;
        public List<Coach> coaches;

        public TrainClass(String classType, String classLabel, int price, List<Coach> coaches) {
            this.classType = classType;
            this.classLabel = classLabel;
            this.price = price;
            this.coaches = coaches;
        }

        public String toJson(String optionId) {
            StringBuilder sb = new StringBuilder("{");
            sb.append("\"classType\":\"").append(classType).append("\",");
            sb.append("\"classLabel\":\"").append(classLabel).append("\",");
            sb.append("\"price\":").append(price).append(",");
            sb.append("\"coaches\":[");
            for (int i = 0; i < coaches.size(); i++) {
                sb.append(coaches.get(i).toJson(optionId, classType));
                if (i < coaches.size() - 1) sb.append(",");
            }
            sb.append("]}");
            return sb.toString();
        }
    }

    public static class TransportOption {
        public String id, type, name, classType, origin, destination;
        public int price, durationMinutes, totalSeats;
        public String departureTime, arrivalTime, operator, seatLayout;
        public String[] amenities;
        public List<TrainClass> classes;
        public String journeyDate; // New field for JSON output

        // For Bus/Launch (single layout)
        public TransportOption(String id, String type, String name, String classType,
                               String origin, String destination, int price, int durationMinutes,
                               String departureTime, String arrivalTime,
                               String[] amenities, String operator, int totalSeats, String seatLayout) {
            this.id = id; this.type = type; this.name = name; this.classType = classType;
            this.origin = origin; this.destination = destination; this.price = price;
            this.durationMinutes = durationMinutes; this.departureTime = departureTime;
            this.arrivalTime = arrivalTime; this.amenities = amenities; this.operator = operator;
            this.totalSeats = totalSeats; this.seatLayout = seatLayout;
            this.classes = new ArrayList<>();
        }

        // For Train (multiple classes/layouts)
        public TransportOption(String id, String type, String name,
                               String origin, String destination, int price, int durationMinutes,
                               String departureTime, String arrivalTime,
                               String[] amenities, String operator, List<TrainClass> classes) {
            this.id = id; this.type = type; this.name = name; this.classType = "MULTIPLE";
            this.origin = origin; this.destination = destination; this.price = price; // from ৳ price
            this.durationMinutes = durationMinutes; this.departureTime = departureTime;
            this.arrivalTime = arrivalTime; this.amenities = amenities; this.operator = operator;
            this.totalSeats = 0; this.seatLayout = "MULTIPLE";
            this.classes = classes;
        }

        public String amenitiesToJson() {
            StringBuilder sb = new StringBuilder("[");
            for (int i = 0; i < amenities.length; i++) {
                sb.append("\"").append(amenities[i]).append("\"");
                if (i < amenities.length - 1) sb.append(",");
            }
            return sb.append("]").toString();
        }

        public String toJson() {
            StringBuilder sb = new StringBuilder("{");
            sb.append("\"id\":\"").append(id).append("\",");
            sb.append("\"type\":\"").append(type).append("\",");
            sb.append("\"name\":\"").append(JsonUtil.escapeString(name)).append("\",");
            sb.append("\"classType\":\"").append(classType).append("\",");
            sb.append("\"origin\":\"").append(origin).append("\",");
            sb.append("\"destination\":\"").append(destination).append("\",");
            sb.append("\"price\":").append(price).append(",");
            sb.append("\"durationMinutes\":").append(durationMinutes).append(",");
            sb.append("\"departureTime\":\"").append(departureTime).append("\",");
            sb.append("\"arrivalTime\":\"").append(arrivalTime).append("\",");
            if (journeyDate != null) sb.append("\"journeyDate\":\"").append(journeyDate).append("\",");
            sb.append("\"amenities\":").append(amenitiesToJson()).append(",");
            sb.append("\"operator\":\"").append(JsonUtil.escapeString(operator)).append("\",");
            sb.append("\"totalSeats\":").append(totalSeats).append(",");
            if (classes == null || classes.isEmpty()) {
                int avail = BookingStore.getAvailableCount(id, totalSeats);
                sb.append("\"availableSeats\":").append(avail).append(",");
            } else {
                sb.append("\"availableSeats\":0,");
            }
            sb.append("\"seatLayout\":\"").append(seatLayout).append("\",");
            sb.append("\"classes\":[");
            if (classes != null) {
                for (int i = 0; i < classes.size(); i++) {
                    sb.append(classes.get(i).toJson(id));
                    if (i < classes.size() - 1) sb.append(",");
                }
            }
            sb.append("]");
            return sb.append("}").toString();
        }

        public String toPromptLine() {
            StringBuilder a = new StringBuilder();
            for (int i = 0; i < amenities.length; i++) {
                a.append(amenities[i]);
                if (i < amenities.length - 1) a.append(", ");
            }
            return id + " | " + type + " | " + classType + " | \u09F3" + price + " | "
                    + durationMinutes + " min | " + a;
        }
    }

    private static final List<TransportOption> ALL = new ArrayList<>();

    private static void addBus(String id, String name, String o, String d, int price, int dur,
                               String dep, String arr, String[] am, String op) {
        ALL.add(new TransportOption(id, "BUS", name, "BUS", o, d, price, dur, dep, arr, am, op, 40, "BUS_2x2"));
    }

    private static void addLaunch(String id, String name, String o, String d, int price, int dur,
                                  String dep, String arr, String[] am, String op, String cls, int seats, String layout) {
        ALL.add(new TransportOption(id, "LAUNCH", name, cls, o, d, price, dur, dep, arr, am, op, seats, layout));
    }

    private static void addTrain(String id, String name, String o, String d, int price, int dur,
                                 String dep, String arr, String[] am, String op, List<TrainClass> classes) {
        ALL.add(new TransportOption(id, "TRAIN", name, o, d, price, dur, dep, arr, am, op, classes));
    }

    static {
        String[] busAC = {"AC","WiFi","Reclining Seats","USB Charging"};
        String[] busNAC = {"Fan","Curtain"};
        String[] trainAm = {"WiFi","Power Outlets","Luggage Rack","Food Service"};
        String[] deckAm = {"Open Air","Food Stall","Scenic River Views"};
        String[] cabinAm = {"Private Cabin","AC","Attached Bathroom","River View"};

        List<Coach> shobhon3 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 80, "SHOBHON"), new Coach("Kha", "Kha (\u0996) Coach", 80, "SHOBHON"), new Coach("Ga", "Ga (\u0997) Coach", 80, "SHOBHON"));
        List<Coach> shobhon2 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 80, "SHOBHON"), new Coach("Kha", "Kha (\u0996) Coach", 80, "SHOBHON"));
        List<Coach> shobhon1 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 80, "SHOBHON"));

        List<Coach> shobhonChair2 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 60, "SHOBHON_CHAIR"), new Coach("Kha", "Kha (\u0996) Coach", 60, "SHOBHON_CHAIR"));
        List<Coach> shobhonChair1 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 60, "SHOBHON_CHAIR"));

        List<Coach> snigdha2 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 52, "SNIGDHA"), new Coach("Kha", "Kha (\u0996) Coach", 52, "SNIGDHA"));
        List<Coach> snigdha1 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 52, "SNIGDHA"));

        List<Coach> acBerth1 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 40, "AC_BERTH"));
        List<Coach> acFirst1 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 24, "AC_FIRST"));
        
        List<Coach> firstSeat1 = List.of(new Coach("Ka", "Ka (\u0995) Coach", 52, "FIRST_SEAT"));

        // ═══ PABNA ↔ DHAKA ═══
        addBus("PAB-DHK-B1", "Shyamoli NR AC", "Pabna", "Dhaka", 450, 220, "07:00", "10:40", busAC, "Shyamoli NR");
        addBus("PAB-DHK-B2", "Hanif Enterprise", "Pabna", "Dhaka", 400, 240, "08:00", "12:00", busAC, "Hanif Enterprise");
        addBus("PAB-DHK-B3", "BRTC Non-AC", "Pabna", "Dhaka", 250, 300, "06:30", "11:30", busNAC, "BRTC");

        addTrain("PAB-DHK-T1", "Silk City Express (726)", "Pabna", "Dhaka", 215, 255, "08:45", "13:00", trainAm, "Bangladesh Railway", 
            List.of(new TrainClass("SHOBHON", "Shobhon", 215, shobhon3), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 260, shobhonChair2), new TrainClass("SNIGDHA", "Snigdha", 695, snigdha2), new TrainClass("AC_BERTH", "AC Berth", 1247, acBerth1)));
        
        addTrain("PAB-DHK-T2", "Padma Express (760)", "Pabna", "Dhaka", 215, 260, "14:00", "18:20", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 215, shobhon3), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 260, shobhonChair2), new TrainClass("SNIGDHA", "Snigdha", 695, snigdha1)));

        addTrain("PAB-DHK-T3", "Banalata Express (796)", "Pabna", "Dhaka", 695, 260, "06:40", "11:00", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SNIGDHA", "Snigdha", 695, snigdha2), new TrainClass("AC_BERTH", "AC Berth", 1247, acBerth1), new TrainClass("AC_FIRST", "AC First", 1575, acFirst1)));

        // Dhaka -> Pabna (reverse)
        addBus("DHK-PAB-B1", "Shyamoli NR AC", "Dhaka", "Pabna", 450, 220, "07:00", "10:40", busAC, "Shyamoli NR");
        addTrain("DHK-PAB-T1", "Silk City Express (725)", "Dhaka", "Pabna", 215, 255, "08:45", "13:00", trainAm, "Bangladesh Railway", 
            List.of(new TrainClass("SHOBHON", "Shobhon", 215, shobhon3), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 260, shobhonChair2), new TrainClass("SNIGDHA", "Snigdha", 695, snigdha2), new TrainClass("AC_BERTH", "AC Berth", 1247, acBerth1)));

        // ═══ PABNA ↔ RAJSHAHI ═══
        addBus("PAB-RAJ-B1", "Local AC Coach", "Pabna", "Rajshahi", 120, 90, "08:00", "09:30", busAC, "Local");
        addBus("PAB-RAJ-B2", "BRTC Local", "Pabna", "Rajshahi", 80, 110, "07:30", "09:20", busNAC, "BRTC");

        addTrain("PAB-RAJ-T1", "Silk City Express", "Pabna", "Rajshahi", 85, 90, "07:00", "08:30", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 85, shobhon2), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 110, shobhonChair1), new TrainClass("SNIGDHA", "Snigdha", 290, snigdha1)));
            
        addTrain("PAB-RAJ-T2", "Local Intercity", "Pabna", "Rajshahi", 85, 100, "11:00", "12:40", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 85, shobhon2), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 110, shobhonChair1)));

        addBus("RAJ-PAB-B1", "Local AC Coach", "Rajshahi", "Pabna", 120, 90, "08:00", "09:30", busAC, "Local");

        // ═══ PABNA ↔ NATORE ═══
        addBus("PAB-NAT-B1", "Local Mini Bus", "Pabna", "Natore", 60, 50, "08:00", "08:50", busNAC, "Local");
        addBus("PAB-NAT-B2", "BRTC Local", "Pabna", "Natore", 50, 60, "08:30", "09:30", busNAC, "BRTC");
        addTrain("PAB-NAT-T1", "Local Passenger", "Pabna", "Natore", 50, 60, "09:00", "10:00", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 50, shobhon1), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 80, shobhonChair1)));
        addBus("NAT-PAB-B1", "Local Mini Bus", "Natore", "Pabna", 60, 50, "08:00", "08:50", busNAC, "Local");

        // ═══ PABNA ↔ NAOGAON ═══
        addBus("PAB-NAO-B1", "Naogaon Express AC", "Pabna", "Naogaon", 200, 150, "08:00", "10:30", busAC, "Naogaon Express");
        addBus("PAB-NAO-B2", "Local Non-AC", "Pabna", "Naogaon", 130, 180, "07:30", "10:30", busNAC, "Local");
        addBus("NAO-PAB-B1", "Naogaon Express AC", "Naogaon", "Pabna", 200, 150, "08:00", "10:30", busAC, "Naogaon Express");

        // ═══ PABNA ↔ BOGURA ═══
        addBus("PAB-BOG-B1", "Shyamoli AC", "Pabna", "Bogura", 280, 160, "08:00", "10:40", busAC, "Shyamoli");
        addBus("PAB-BOG-B2", "Local Non-AC", "Pabna", "Bogura", 180, 200, "07:30", "11:10", busNAC, "Local");
        addTrain("PAB-BOG-T1", "Rangpur Express", "Pabna", "Bogura", 150, 150, "10:00", "12:30", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 150, shobhon2), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 190, shobhonChair1), new TrainClass("SNIGDHA", "Snigdha", 480, snigdha1)));
        addBus("BOG-PAB-B1", "Shyamoli AC", "Bogura", "Pabna", 280, 160, "08:00", "10:40", busAC, "Shyamoli");

        // ═══ PABNA ↔ SIRAJGANJ ═══
        addBus("PAB-SIR-B1", "Local AC Coach", "Pabna", "Sirajganj", 110, 80, "09:00", "10:20", busAC, "Local");
        addBus("PAB-SIR-B2", "Local Non-AC", "Pabna", "Sirajganj", 70, 100, "08:30", "10:10", busNAC, "Local");
        addBus("SIR-PAB-B1", "Local AC Coach", "Sirajganj", "Pabna", 110, 80, "09:00", "10:20", busAC, "Local");

        // ═══ PABNA ↔ KUSHTIA ═══
        addBus("PAB-KUS-B1", "Shyamoli AC", "Pabna", "Kushtia", 150, 100, "08:00", "09:40", busAC, "Shyamoli");
        addBus("PAB-KUS-B2", "Local Non-AC", "Pabna", "Kushtia", 90, 130, "07:30", "09:40", busNAC, "Local");
        addBus("KUS-PAB-B1", "Shyamoli AC", "Kushtia", "Pabna", 150, 100, "08:00", "09:40", busAC, "Shyamoli");

        // ═══ PABNA ↔ RANGPUR ═══
        addBus("PAB-RAN-B1", "Green Line AC", "Pabna", "Rangpur", 480, 240, "07:30", "11:30", busAC, "Green Line");
        addBus("PAB-RAN-B2", "BRTC Non-AC", "Pabna", "Rangpur", 300, 300, "07:00", "12:00", busNAC, "BRTC");
        addTrain("PAB-RAN-T1", "Rangpur Express (773)", "Pabna", "Rangpur", 250, 240, "10:30", "14:30", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 250, shobhon3), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 310, shobhonChair2), new TrainClass("SNIGDHA", "Snigdha", 750, snigdha1)));
        addTrain("PAB-RAN-T2", "Lalmonirhat Express (751)", "Pabna", "Rangpur", 250, 270, "22:00", "02:30", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 250, shobhon2), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 310, shobhonChair1), new TrainClass("SNIGDHA", "Snigdha", 750, snigdha1), new TrainClass("AC_BERTH", "AC Berth", 1300, acBerth1)));
        addBus("RAN-PAB-B1", "Green Line AC", "Rangpur", "Pabna", 480, 240, "07:30", "11:30", busAC, "Green Line");

        // ═══ PABNA ↔ MYMENSINGH ═══
        addBus("PAB-MYM-B1", "Shyamoli AC", "Pabna", "Mymensingh", 450, 270, "07:00", "11:30", busAC, "Shyamoli");
        addBus("PAB-MYM-B2", "Eagle Non-AC", "Pabna", "Mymensingh", 280, 330, "06:30", "12:00", busNAC, "Eagle");
        addBus("MYM-PAB-B1", "Shyamoli AC", "Mymensingh", "Pabna", 450, 270, "07:00", "11:30", busAC, "Shyamoli");

        // ═══ PABNA ↔ SYLHET ═══
        addBus("PAB-SYL-B1", "Green Line AC", "Pabna", "Sylhet", 850, 420, "07:00", "14:00", busAC, "Green Line");
        addBus("PAB-SYL-B2", "Hanif Non-AC", "Pabna", "Sylhet", 550, 480, "06:30", "14:30", busNAC, "Hanif");
        addTrain("PAB-SYL-T1", "Upaban Express (via Dhaka)", "Pabna", "Sylhet", 490, 660, "09:00", "20:00", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 490, shobhon2), new TrainClass("SNIGDHA", "Snigdha", 1250, snigdha1), new TrainClass("AC_BERTH", "AC Berth", 2100, acBerth1)));
        addBus("SYL-PAB-B1", "Green Line AC", "Sylhet", "Pabna", 850, 420, "07:00", "14:00", busAC, "Green Line");

        // ═══ PABNA ↔ CHATTOGRAM ═══
        addBus("PAB-CTG-B1", "Green Line AC", "Pabna", "Chattogram", 1000, 480, "08:00", "16:00", busAC, "Green Line");
        addBus("PAB-CTG-B2", "Shyamoli AC", "Pabna", "Chattogram", 950, 480, "07:30", "15:30", busAC, "Shyamoli");
        addBus("PAB-CTG-B3", "BRTC Non-AC", "Pabna", "Chattogram", 600, 540, "07:00", "16:00", busNAC, "BRTC");
        addTrain("PAB-CTG-T1", "Subarna Express (via Dhaka)", "Pabna", "Chattogram", 530, 690, "07:00", "18:30", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 530, shobhon2), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 640, shobhonChair1), new TrainClass("SNIGDHA", "Snigdha", 1400, snigdha1), new TrainClass("AC_BERTH", "AC Berth", 2450, acBerth1)));
        addTrain("PAB-CTG-T2", "Mahanagar Probhati (via Dhaka)", "Pabna", "Chattogram", 530, 690, "06:00", "17:30", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 530, shobhon2), new TrainClass("SNIGDHA", "Snigdha", 1400, snigdha1), new TrainClass("AC_FIRST", "AC First", 3100, acFirst1)));
        addBus("CTG-PAB-B1", "Green Line AC", "Chattogram", "Pabna", 1000, 480, "08:00", "16:00", busAC, "Green Line");

        // ═══ PABNA ↔ KHULNA ═══
        addBus("PAB-KHL-B1", "Green Line AC", "Pabna", "Khulna", 650, 360, "07:00", "13:00", busAC, "Green Line");
        addBus("PAB-KHL-B2", "BRTC Non-AC", "Pabna", "Khulna", 400, 420, "06:30", "13:30", busNAC, "BRTC");
        addTrain("PAB-KHL-T1", "Rupsha Express", "Pabna", "Khulna", 350, 450, "09:00", "16:30", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 350, shobhon2), new TrainClass("SHOBHON_CHAIR", "Shobhon Chair", 440, shobhonChair1), new TrainClass("SNIGDHA", "Snigdha", 1050, snigdha1), new TrainClass("AC_BERTH", "AC Berth", 1800, acBerth1)));
        addLaunch("PAB-KHL-L1", "BIWTC River Launch", "Pabna", "Khulna", 300, 840, "18:00", "08:00", deckAm, "BIWTC", "DECK", 48, "LAUNCH_DECK");
        addLaunch("PAB-KHL-L2", "BIWTC River Launch", "Pabna", "Khulna", 1800, 840, "18:00", "08:00", cabinAm, "BIWTC", "VIP_CABIN", 10, "LAUNCH_CABIN");
        addBus("KHL-PAB-B1", "Green Line AC", "Khulna", "Pabna", 650, 360, "07:00", "13:00", busAC, "Green Line");

        // ═══ PABNA ↔ BARISAL ═══
        addBus("PAB-BAR-B1", "Shyamoli AC", "Pabna", "Barisal", 650, 360, "07:00", "13:00", busAC, "Shyamoli");
        addBus("PAB-BAR-B2", "Eagle Non-AC", "Pabna", "Barisal", 400, 420, "06:30", "13:30", busNAC, "Eagle");
        addLaunch("PAB-BAR-L1", "BIWTC Rocket Steamer", "Pabna", "Barisal", 280, 720, "20:00", "08:00", deckAm, "BIWTC", "DECK", 48, "LAUNCH_DECK");
        addLaunch("PAB-BAR-L2", "BIWTC Rocket Steamer", "Pabna", "Barisal", 1200, 720, "20:00", "08:00", cabinAm, "BIWTC", "SINGLE_CABIN", 12, "LAUNCH_CABIN");
        addLaunch("PAB-BAR-L3", "BIWTC Rocket Steamer", "Pabna", "Barisal", 2200, 720, "20:00", "08:00", cabinAm, "BIWTC", "DOUBLE_CABIN", 8, "LAUNCH_CABIN");
        addLaunch("PAB-BAR-L4", "BIWTC Rocket Steamer", "Pabna", "Barisal", 3500, 720, "20:00", "08:00", cabinAm, "BIWTC", "VIP_CABIN", 4, "LAUNCH_CABIN");
        addBus("BAR-PAB-B1", "Shyamoli AC", "Barisal", "Pabna", 650, 360, "07:00", "13:00", busAC, "Shyamoli");

        // ═══ PABNA ↔ ISHWARDI ═══
        addBus("PAB-ISH-B1", "Local Mini", "Pabna", "Ishwardi", 40, 30, "08:00", "08:30", busNAC, "Local");
        addTrain("PAB-ISH-T1", "Passing Express", "Pabna", "Ishwardi", 50, 30, "08:30", "09:00", trainAm, "Bangladesh Railway",
            List.of(new TrainClass("SHOBHON", "Shobhon", 50, shobhon1)));
        addBus("ISH-PAB-B1", "Local Mini", "Ishwardi", "Pabna", 40, 30, "08:00", "08:30", busNAC, "Local");
    }

    private static int parseTimeMinutes(String time) {
        String[] parts = time.split(":");
        return Integer.parseInt(parts[0]) * 60 + Integer.parseInt(parts[1]);
    }

    private static boolean isTimeInSlot(String time, String slot) {
        if (slot == null || slot.isBlank() || "Any Time".equalsIgnoreCase(slot)) return true;
        int mins = parseTimeMinutes(time);
        if ("Early Morning (5AM–8AM)".equalsIgnoreCase(slot)) return mins >= 5 * 60 && mins < 8 * 60;
        if ("Morning (8AM–12PM)".equalsIgnoreCase(slot)) return mins >= 8 * 60 && mins < 12 * 60;
        if ("Afternoon (12PM–5PM)".equalsIgnoreCase(slot)) return mins >= 12 * 60 && mins < 17 * 60;
        if ("Evening (5PM–9PM)".equalsIgnoreCase(slot)) return mins >= 17 * 60 && mins < 21 * 60;
        if ("Night (9PM–5AM)".equalsIgnoreCase(slot)) return mins >= 21 * 60 || mins < 5 * 60;
        return true;
    }

    public static List<TransportOption> getOptions(String origin, String destination, String preferredTimeSlot, String travelDate) {
        List<TransportOption> results = new ArrayList<>();
        String o = origin.trim().toLowerCase();
        String d = destination.trim().toLowerCase();
        for (TransportOption opt : ALL) {
            if (opt.origin.toLowerCase().equals(o) && opt.destination.toLowerCase().equals(d)) {
                if (isTimeInSlot(opt.departureTime, preferredTimeSlot)) {
                    // Clone to set journeyDate without mutating static mock data
                    TransportOption copy = new TransportOption(opt.id, opt.type, opt.name, opt.origin, opt.destination, opt.price, opt.durationMinutes, opt.departureTime, opt.arrivalTime, opt.amenities, opt.operator, opt.classes);
                    copy.classType = opt.classType;
                    copy.totalSeats = opt.totalSeats;
                    copy.seatLayout = opt.seatLayout;
                    copy.journeyDate = travelDate;
                    results.add(copy);
                }
            }
        }
        return results;
    }

    public static TransportOption getById(String id) {
        for (TransportOption opt : ALL) {
            if (opt.id.equals(id)) return opt;
        }
        return null;
    }

    public static List<String> getCities() {
        List<String> cities = new ArrayList<>();
        cities.add("Pabna"); cities.add("Dhaka"); cities.add("Chattogram"); 
        cities.add("Rajshahi"); cities.add("Khulna"); cities.add("Barisal");
        cities.add("Sylhet"); cities.add("Rangpur"); cities.add("Mymensingh");
        cities.add("Natore"); cities.add("Naogaon"); cities.add("Bogura");
        cities.add("Kushtia"); cities.add("Sirajganj"); cities.add("Ishwardi");
        return cities;
    }

    /** Generate seat list JSON for a given option. */
    public static String getSeatsJson(TransportOption opt, String classType, String coachId) {
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"optionId\":\"").append(opt.id).append("\",");

        String layout = opt.seatLayout;
        int totalSeats = opt.totalSeats;
        String prefix = opt.id;
        
        if ("TRAIN".equals(opt.type)) {
            TrainClass selectedClass = null;
            for (TrainClass tc : opt.classes) {
                if (tc.classType.equals(classType)) {
                    selectedClass = tc; break;
                }
            }
            if (selectedClass != null) {
                Coach selectedCoach = null;
                for (Coach c : selectedClass.coaches) {
                    if (c.coachId.equals(coachId)) {
                        selectedCoach = c; break;
                    }
                }
                if (selectedCoach != null) {
                    layout = selectedCoach.layout;
                    totalSeats = selectedCoach.totalSeats;
                    prefix = opt.id + "_" + classType + "_" + coachId;
                }
            }
        }

        sb.append("\"layoutType\":\"").append(layout).append("\",");
        sb.append("\"totalSeats\":").append(totalSeats).append(",");
        int avail = BookingStore.getAvailableCount(prefix, totalSeats);
        sb.append("\"availableCount\":").append(avail).append(",");
        sb.append("\"seats\":[");

        List<String> seatEntries = new ArrayList<>();
        if ("BUS_2x2".equals(layout)) {
            String[] pos = {"A","B","C","D"};
            for (int row = 1; row <= 10; row++) {
                for (String p : pos) {
                    String id = row + p;
                    boolean taken = BookingStore.isSeatTaken(prefix, id);
                    boolean window = p.equals("A") || p.equals("D");
                    seatEntries.add("{\"id\":\"" + id + "\",\"row\":" + row
                        + ",\"position\":\"" + p + "\",\"isWindow\":" + window
                        + ",\"status\":\"" + (taken ? "OCCUPIED" : "AVAILABLE") + "\"}");
                }
            }
        } else if ("SHOBHON".equals(layout)) {
            String[] pos = {"A","B","C","D","E"};
            for (int row = 1; row <= 16; row++) {
                for (String p : pos) {
                    String id = row + p;
                    boolean taken = BookingStore.isSeatTaken(prefix, id);
                    boolean window = p.equals("A") || p.equals("E");
                    seatEntries.add("{\"id\":\"" + id + "\",\"row\":" + row
                        + ",\"position\":\"" + p + "\",\"isWindow\":" + window
                        + ",\"status\":\"" + (taken ? "OCCUPIED" : "AVAILABLE") + "\"}");
                }
            }
        } else if ("SHOBHON_CHAIR".equals(layout) || "FIRST_SEAT".equals(layout) || "SNIGDHA".equals(layout)) {
            String[] pos = {"W1","W2","M1","M2"};
            for (int row = 1; row <= 13; row++) { // 13*4 = 52. If 60 for SHOBHON_CHAIR, 15 rows.
                int rows = "SHOBHON_CHAIR".equals(layout) ? 15 : 13;
                if (row > rows) break;
                for (String p : pos) {
                    String id = row + p;
                    boolean taken = BookingStore.isSeatTaken(prefix, id);
                    boolean window = p.startsWith("W");
                    seatEntries.add("{\"id\":\"" + id + "\",\"row\":" + row
                        + ",\"position\":\"" + p + "\",\"isWindow\":" + window
                        + ",\"status\":\"" + (taken ? "OCCUPIED" : "AVAILABLE") + "\"}");
                }
            }
        } else if ("AC_BERTH".equals(layout)) {
            String[] pos = {"L", "U"};
            for (int bay = 1; bay <= 20; bay++) {
                for (String p : pos) {
                    String id = bay + p;
                    boolean taken = BookingStore.isSeatTaken(prefix, id);
                    seatEntries.add("{\"id\":\"" + id + "\",\"row\":" + bay
                        + ",\"position\":\"" + p + "\",\"isWindow\":false"
                        + ",\"status\":\"" + (taken ? "OCCUPIED" : "AVAILABLE") + "\"}");
                }
            }
        } else if ("AC_FIRST".equals(layout)) {
            String[] pos = {"1L", "1U", "2L", "2U"};
            for (int comp = 1; comp <= 6; comp++) {
                for (String p : pos) {
                    String id = "C" + comp + "-" + p;
                    boolean taken = BookingStore.isSeatTaken(prefix, id);
                    seatEntries.add("{\"id\":\"" + id + "\",\"row\":" + comp
                        + ",\"position\":\"" + p + "\",\"isWindow\":false"
                        + ",\"status\":\"" + (taken ? "OCCUPIED" : "AVAILABLE") + "\"}");
                }
            }
        } else if ("LAUNCH_DECK".equals(layout)) {
            for (int i = 1; i <= 48; i++) {
                String id = "D" + i;
                boolean taken = BookingStore.isSeatTaken(prefix, id);
                int row = (i - 1) / 8 + 1;
                seatEntries.add("{\"id\":\"" + id + "\",\"row\":" + row
                    + ",\"position\":\"D\",\"isWindow\":false"
                    + ",\"status\":\"" + (taken ? "OCCUPIED" : "AVAILABLE") + "\"}");
            }
        } else if ("LAUNCH_CABIN".equals(layout)) {
            for (int i = 1; i <= totalSeats; i++) {
                String id = "C" + i;
                boolean taken = BookingStore.isSeatTaken(prefix, id);
                seatEntries.add("{\"id\":\"" + id + "\",\"row\":" + ((i - 1) / 2 + 1)
                    + ",\"position\":\"C\",\"isWindow\":false"
                    + ",\"status\":\"" + (taken ? "OCCUPIED" : "AVAILABLE") + "\"}");
            }
        }
        sb.append(String.join(",", seatEntries));
        sb.append("]}");
        return sb.toString();
    }
}
