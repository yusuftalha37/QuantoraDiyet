/// Zengin Türk mutfağı tarif kataloğu (demo ve yerel öneriler için).
/// Her tarif: tür, ad, malzemeler, adım adım yapılış, süre ve porsiyon.
class RecipeCatalog {
  static const List<Map<String, dynamic>> breakfasts = [
    {
      'type': 'breakfast', 'name': 'Menemen', 'prep_minutes': 15, 'servings': 2,
      'ingredients': ['3 yumurta', '2 domates', '2 yeşil biber', 'zeytinyağı', 'tuz', 'karabiber'],
      'steps': [
        'Biberleri küçük küçük doğrayıp zeytinyağında 3-4 dakika kavurun.',
        'Rendelenmiş veya küp doğranmış domatesi ekleyip suyunu çekene kadar pişirin.',
        'Tuz ve karabiber ekleyin.',
        'Yumurtaları kırıp hafifçe karıştırarak istediğiniz kıvamda pişirin.',
        'Sıcak ekmekle servis edin.',
      ],
    },
    {
      'type': 'breakfast', 'name': 'Peynirli Omlet', 'prep_minutes': 10, 'servings': 1,
      'ingredients': ['2 yumurta', '1 avuç rendelenmiş kaşar', '1 tatlı kaşığı tereyağı', 'maydanoz', 'tuz'],
      'steps': [
        'Yumurtaları tuzla birlikte iyice çırpın.',
        'Tavada tereyağını eritin.',
        'Yumurtayı dökün, kenarları tutmaya başlayınca kaşarı serpin.',
        'İkiye katlayıp 1 dakika daha pişirin, maydanozla servis edin.',
      ],
    },
    {
      'type': 'breakfast', 'name': 'Sucuklu Yumurta', 'prep_minutes': 12, 'servings': 2,
      'ingredients': ['6-8 dilim sucuk', '3 yumurta', 'karabiber'],
      'steps': [
        'Sucukları tavada kendi yağı çıkana kadar çevirin.',
        'Üzerine yumurtaları kırın.',
        'Sarıları dağıtmadan, beyazlar pişene kadar kısık ateşte tutun.',
        'Karabiber serpip sıcak servis edin.',
      ],
    },
    {
      'type': 'breakfast', 'name': 'Yulaflı Meyve Kâsesi', 'prep_minutes': 8, 'servings': 1,
      'ingredients': ['1 su bardağı süt', '4 kaşık yulaf', '1 muz', '1 kaşık bal', 'tarçın', 'ceviz'],
      'steps': [
        'Yulafı sütle birlikte 3-4 dakika kısık ateşte pişirin.',
        'Kâseye alıp dilimlenmiş muzu üzerine dizin.',
        'Bal gezdirin, ceviz ve tarçın serpin.',
      ],
    },
    {
      'type': 'breakfast', 'name': 'Serpme Kahvaltı Tabağı', 'prep_minutes': 10, 'servings': 2,
      'ingredients': ['beyaz peynir', 'zeytin', 'domates', 'salatalık', 'bal', 'tereyağı', 'ekmek'],
      'steps': [
        'Peynir, zeytin ve tereyağını tabağa yerleştirin.',
        'Domates ve salatalığı dilimleyip ekleyin.',
        'Bir köşeye bal-tereyağı koyun.',
        'Taze ekmekle servis edin.',
      ],
    },
  ];

  /// Öğle/akşam için ana yemekler (çorbalar dâhil geniş havuz).
  static const List<Map<String, dynamic>> mains = [
    {
      'type': 'lunch', 'name': 'Mercimek Çorbası', 'prep_minutes': 35, 'servings': 4,
      'ingredients': ['1 su bardağı kırmızı mercimek', '1 soğan', '1 havuç', '1 patates', '1 kaşık un', 'tuz', 'kimyon'],
      'steps': [
        'Doğranmış soğanı yağda pembeleşene kadar kavurun.',
        'Unu ekleyip 1 dakika kavurun.',
        'Yıkanmış mercimek, küp doğranmış havuç ve patatesi ekleyin.',
        '1.5 litre su ile sebzeler yumuşayana kadar (~25 dk) pişirin.',
        'Blenderdan geçirip tuz ve kimyon ekleyin, limonla servis edin.',
      ],
    },
    {
      'type': 'lunch', 'name': 'Ezogelin Çorbası', 'prep_minutes': 35, 'servings': 4,
      'ingredients': ['kırmızı mercimek', 'pirinç', 'bulgur', 'soğan', 'salça', 'nane', 'pul biber'],
      'steps': [
        'Soğanı yağda kavurun, salçayı ekleyip 1 dakika çevirin.',
        'Mercimek, pirinç ve bulguru ekleyin.',
        'Su ekleyip tüm taneler yumuşayana kadar pişirin.',
        'Üzerine kızdırılmış tereyağında nane ve pul biber gezdirin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'Izgara Tavuk ve Bulgur Pilavı', 'prep_minutes': 30, 'servings': 2,
      'ingredients': ['2 tavuk göğsü', '1 su bardağı bulgur', '1 domates', '1 soğan', 'zeytinyağı', 'baharat'],
      'steps': [
        'Tavukları baharatlayıp 20 dakika marine edin.',
        'Soğanı kavurup domates ve salça ekleyin, bulguru katın.',
        'İki ölçü sıcak su ekleyip bulgur suyunu çekene kadar pişirin, demlendirin.',
        'Tavukları ızgarada her iki yüzü pişene kadar çevirin.',
        'Pilavla birlikte servis edin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'Fırında Tavuk ve Sebze', 'prep_minutes': 50, 'servings': 4,
      'ingredients': ['tavuk but', 'patates', 'havuç', 'soğan', 'zeytinyağı', 'kekik', 'sarımsak'],
      'steps': [
        'Sebzeleri iri doğrayıp fırın kabına dizin.',
        'Tavukları üzerine yerleştirin.',
        'Zeytinyağı, ezilmiş sarımsak, kekik, tuz ile harmanlayın.',
        '200°C fırında 40-45 dakika, üzeri kızarana kadar pişirin.',
      ],
    },
    {
      'type': 'lunch', 'name': 'Etli Nohut ve Pirinç Pilavı', 'prep_minutes': 60, 'servings': 4,
      'ingredients': ['1 su bardağı haşlanmış nohut', '250 g kuşbaşı et', '1 soğan', 'salça', 'pirinç', 'tuz'],
      'steps': [
        'Eti kendi suyunu çekene kadar kavurun.',
        'Doğranmış soğanı ekleyip pembeleştirin.',
        'Salçayı ekleyip çevirin, nohut ve sıcak su ekleyin.',
        'Et yumuşayana kadar (~35 dk) pişirin.',
        'Yanında tereyağlı pirinç pilavı ile servis edin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'Kıymalı Taze Fasulye', 'prep_minutes': 40, 'servings': 4,
      'ingredients': ['500 g taze fasulye', '150 g kıyma', '1 soğan', '1 domates', 'salça', 'zeytinyağı'],
      'steps': [
        'Kıymayı soğanla birlikte kavurun.',
        'Salça ve domatesi ekleyip çevirin.',
        'Ayıklanmış fasulyeleri ekleyin, bir bardak sıcak su ilave edin.',
        'Kısık ateşte fasulyeler yumuşayana kadar pişirin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'Karnıyarık', 'prep_minutes': 55, 'servings': 4,
      'ingredients': ['4 patlıcan', '200 g kıyma', '1 soğan', '2 domates', 'biber', 'salça', 'sıvı yağ'],
      'steps': [
        'Patlıcanları alacalı soyup kızartın (veya fırınlayın).',
        'Kıyma, soğan, domates ve salçadan iç harç hazırlayın.',
        'Patlıcanları ortadan yarıp harçla doldurun.',
        'Üzerine biber-domates koyup az suyla 180°C fırında 25 dk pişirin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'Fırın Köfte ve Patates', 'prep_minutes': 45, 'servings': 4,
      'ingredients': ['400 g kıyma', '1 soğan', '1 dilim bayat ekmek içi', 'patates', 'domates', 'biber', 'baharat'],
      'steps': [
        'Kıyma, rendelenmiş soğan, ekmek içi ve baharatları yoğurun.',
        'Köfteleri şekillendirip fırın kabına dizin.',
        'Aralara dilimlenmiş patates, domates ve biber yerleştirin.',
        'Üzerine salçalı su gezdirip 200°C fırında 35 dk pişirin.',
      ],
    },
    {
      'type': 'lunch', 'name': 'Sebzeli Tavuk Sote', 'prep_minutes': 30, 'servings': 3,
      'ingredients': ['2 tavuk göğsü', 'biber', 'soğan', 'domates', 'mantar', 'zeytinyağı'],
      'steps': [
        'Kuşbaşı tavukları yüksek ateşte mühürleyin.',
        'Doğranmış soğan ve biberleri ekleyip kavurun.',
        'Mantar ve domatesi ekleyin.',
        'Kısık ateşte sular çekilene kadar sote edin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'Fırında Somon ve Sebze', 'prep_minutes': 30, 'servings': 2,
      'ingredients': ['2 somon fileto', 'brokoli', 'limon', 'zeytinyağı', 'karabiber'],
      'steps': [
        'Somonları zeytinyağı, limon ve karabiberle marine edin.',
        'Fırın kağıdına alıp yanına brokoli dizin.',
        '200°C fırında 18-20 dakika pişirin.',
        'Limon dilimiyle servis edin.',
      ],
    },
    {
      'type': 'lunch', 'name': 'Mercimek Köftesi', 'prep_minutes': 40, 'servings': 4,
      'ingredients': ['1 su bardağı kırmızı mercimek', '1 su bardağı ince bulgur', 'soğan', 'salça', 'maydanoz', 'limon'],
      'steps': [
        'Mercimeği 2 ölçü suyla yumuşayana kadar haşlayın.',
        'Ateşten alıp bulguru ekleyin, kapağını kapatıp 15 dk bekletin.',
        'Kavrulmuş soğan-salçayı ekleyin, maydanoz ve limonla yoğurun.',
        'Islak elle köfte şekli verip marul yaprağında servis edin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'Zeytinyağlı Barbunya', 'prep_minutes': 50, 'servings': 4,
      'ingredients': ['2 su bardağı barbunya', 'soğan', 'havuç', 'domates', 'salça', 'zeytinyağı', 'şeker'],
      'steps': [
        'Soğan ve havucu zeytinyağında kavurun.',
        'Salça ve domatesi ekleyip çevirin.',
        'Önceden haşlanmış barbunyayı ekleyin, bir tutam şeker katın.',
        'Kısık ateşte 20 dk pişirin, soğuk servis edin.',
      ],
    },
    {
      'type': 'lunch', 'name': 'Domatesli Spagetti', 'prep_minutes': 25, 'servings': 3,
      'ingredients': ['300 g spagetti', '3 domates', '2 diş sarımsak', 'zeytinyağı', 'fesleğen/kekik', 'rende peynir'],
      'steps': [
        'Makarnayı tuzlu suda al dente haşlayın.',
        'Sarımsağı zeytinyağında kokusu çıkana kadar çevirin.',
        'Rendelenmiş domatesi ekleyip sos kıvam alana kadar pişirin.',
        'Süzülmüş makarnayı sosa katın, peynirle servis edin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'Nohutlu Sebze Güveç', 'prep_minutes': 50, 'servings': 4,
      'ingredients': ['haşlanmış nohut', 'patlıcan', 'kabak', 'biber', 'domates', 'patates', 'zeytinyağı'],
      'steps': [
        'Tüm sebzeleri iri küpler halinde doğrayın.',
        'Güveç kabında zeytinyağıyla harmanlayın, nohudu ekleyin.',
        'Salçalı sıcak su gezdirin.',
        '180°C fırında sebzeler yumuşayana kadar (~40 dk) pişirin.',
      ],
    },
    {
      'type': 'lunch', 'name': 'Yayla Çorbası', 'prep_minutes': 30, 'servings': 4,
      'ingredients': ['1 su bardağı yoğurt', '0.5 su bardağı pirinç', '1 yumurta sarısı', '1 kaşık un', 'nane', 'tereyağı'],
      'steps': [
        'Pirinci yumuşayana kadar haşlayın.',
        'Yoğurt, yumurta sarısı ve unu çırpıp terbiye hazırlayın.',
        'Terbiyeyi yavaşça çorbaya katıp sürekli karıştırın.',
        'Kaynayınca tereyağında kavrulmuş nane gezdirin.',
      ],
    },
    {
      'type': 'dinner', 'name': 'İmam Bayıldı', 'prep_minutes': 50, 'servings': 4,
      'ingredients': ['4 patlıcan', '2 soğan', '3 domates', 'sarımsak', 'maydanoz', 'zeytinyağı'],
      'steps': [
        'Patlıcanları alacalı soyup hafif kızartın.',
        'Soğan, sarımsak ve domatesten zeytinyağlı iç hazırlayın.',
        'Patlıcanları yarıp içini doldurun.',
        'Az suyla kısık ateşte 25 dk pişirin, ılık servis edin.',
      ],
    },
  ];

  static const List<Map<String, dynamic>> extras = [
    {
      'type': 'snack', 'name': 'Çoban Salata', 'prep_minutes': 10, 'servings': 2,
      'ingredients': ['domates', 'salatalık', 'soğan', 'maydanoz', 'zeytinyağı', 'limon'],
      'steps': [
        'Tüm sebzeleri küçük küp doğrayın.',
        'Maydanozu ekleyin.',
        'Zeytinyağı, limon ve tuzla karıştırıp servis edin.',
      ],
    },
    {
      'type': 'snack', 'name': 'Cacık', 'prep_minutes': 10, 'servings': 3,
      'ingredients': ['2 su bardağı yoğurt', '1 salatalık', 'sarımsak', 'nane', 'su'],
      'steps': [
        'Yoğurdu ezilmiş sarımsakla çırpın.',
        'Rendelenmiş salatalığı ekleyin.',
        'İstediğiniz kıvamda su ekleyin, nane serpin.',
      ],
    },
  ];
}
