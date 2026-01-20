# fastcycle

Aplikasi ini dibangun menggunakan Flutter dan mengonsumsi data dari OpenWeatherMap API.

Untuk ikon cuaca (awan/hujan), saya me-load langsung dari URL aset OpenWeatherMap berdasarkan kode kondisi cuaca yang diterima. Sedangkan untuk ikon antarmuka lainnya (seperti ikon air atau mata), saya menggunakan Material Design Icons bawaan Flutter.

Beberapa visualisasi seperti kurva matahari dan grafik batang suhu saya bangun sendiri menggunakan Custom Widget dan logika matematika agar tampilannya dinamis mengikuti data.