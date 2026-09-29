import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'domba_masuk_page.dart';
import 'data_domba_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget menuCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget activityTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8F3),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: BottomNavigationBar(
          currentIndex: 0,
          selectedItemColor: const Color(0xff2D6A4F),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,

          items: const [

            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.login),
              label: "Masuk",
            ),

            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xff2D6A4F),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              label: "QR",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.logout),
              label: "Keluar",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: "Nota",
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Halo Admin 👋",
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Ngapak Ngapiki Farm",
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1B4332),
                        ),
                      ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Color(0xff2D6A4F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                "Kelola peternakan modern dengan mudah.",
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1484557985045-edf25e08da73?q=80&w=1200&auto=format&fit=crop',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff2D6A4F),
                      Color(0xff40916C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),

                child: Row(
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            "Scan QR Domba",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Scan QR untuk melihat data domba dengan cepat.",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Text(
                "Menu Cepat",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
                children: [

                  menuCard(
                    context,
                    Icons.account_balance_wallet,
                    "Keuangan",
                    Colors.green,
                    const SizedBox(),
                  ),

                  menuCard(
                    context,
                    Icons.add_circle,
                    "Domba Masuk",
                    Colors.blue,
                    const DombaMasukPage(),
                  ),

                  menuCard(
                    context,
                    Icons.list_alt,
                    "Data Domba",
                    Colors.orange,
                    const DataDombaPage(),
                  ),

                  menuCard(
                    context,
                    Icons.analytics,
                    "Statistik",
                    Colors.red,
                    const SizedBox(),
                  ),

                  menuCard(
                    context,
                    Icons.settings,
                    "Pengaturan",
                    Colors.teal,
                    const SizedBox(),
                  ),

                  menuCard(
                    context,
                    Icons.history,
                    "Riwayat",
                    Colors.deepOrange,
                    const SizedBox(),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Text(
                "Ringkasan",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [

                  infoCard(
                    "Total Domba",
                    "128",
                    Icons.groups,
                    Colors.green,
                  ),

                  infoCard(
                    "Domba Masuk",
                    "35",
                    Icons.add_business,
                    Colors.blue,
                  ),

                  infoCard(
                    "Domba Keluar",
                    "22",
                    Icons.exit_to_app,
                    Colors.orange,
                  ),

                  infoCard(
                    "Berat Rata-rata",
                    "32 KG",
                    Icons.balance,
                    Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Text(
                "Aktivitas Terbaru",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              activityTile(
                "Domba Masuk",
                "5 ekor domba baru masuk",
                Icons.add_circle,
                Colors.green,
              ),

              activityTile(
                "Domba Keluar",
                "2 ekor berhasil terjual",
                Icons.exit_to_app,
                Colors.orange,
              ),

              activityTile(
                "Cetak Nota",
                "Nota transaksi berhasil dibuat",
                Icons.print,
                Colors.blue,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}