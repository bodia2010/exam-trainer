import '../models/smalltalk_exercise.dart';

const List<SmalltalkExercise> b2BerufSmalltalkExercises = [
  SmalltalkExercise(
    id: 'st1',
    number: 1,
    stimulus: 'Ich finde, wir als Praktikant*innen sollten eigentlich keine Überstunden machen. Was meinst du?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, da stimme ich dir zu. Wir sind hier, um zu lernen – nicht um die Arbeit der festen Mitarbeiter zu übernehmen.'),
      DialogLine(isPersonA: true, text: 'Genau. Außerdem bekommen wir oft gar keine Bezahlung für die Überstunden. Das finde ich unfair.'),
      DialogLine(isPersonA: false, text: 'Stimmt. Ich finde, man sollte klare Arbeitszeiten haben. Wenn wir immer länger bleiben, denken die Kollegen vielleicht, dass das normal ist.'),
      DialogLine(isPersonA: true, text: 'Ja, und am Ende wird das von uns erwartet. Dabei brauchen wir ja auch Zeit, um das Gelernte zu verarbeiten.'),
      DialogLine(isPersonA: false, text: 'Vielleicht sollten wir mal mit unserer Betreuerin darüber sprechen. Ich glaube, sie versteht das.'),
      DialogLine(isPersonA: true, text: 'Gute Idee. Es ist wichtig, dass wir von Anfang an offen darüber reden.'),
    ],
    alternatives: [],
  ),
  SmalltalkExercise(
    id: 'st2',
    number: 2,
    stimulus: 'Ich gehe in der Mittagspause meist zum Imbiss um die Ecke. Wo isst du?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich bringe meistens etwas von zu Hause mit. Das ist günstiger und meistens auch gesünder.'),
      DialogLine(isPersonA: true, text: 'Stimmt, das ist eigentlich eine gute Idee. Aber ich habe morgens oft keine Zeit, etwas vorzubereiten.'),
      DialogLine(isPersonA: false, text: 'Verstehe ich. Manchmal hole ich mir auch etwas vom Bäcker, wenn es schnell gehen muss.'),
      DialogLine(isPersonA: true, text: 'Ja, das mache ich auch ab und zu. Besonders wenn es stressig ist. Aber ich versuche, in der Pause wirklich abzuschalten.'),
      DialogLine(isPersonA: false, text: 'Geht mir genauso. Eine ruhige Mittagspause tut gut, damit man wieder Energie hat für den Nachmittag.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Wenn du essen gehst',
        phrases: [
          'Ich esse oft in der Kantine. Da gibt es jeden Tag ein warmes Gericht.',
          'Manchmal gehe ich mit Kolleg*innen essen, das ist auch eine gute Gelegenheit zum Austausch.',
          'Ich mag den Imbiss um die Ecke ganz gern, das Essen ist lecker und geht schnell.',
          'Ab und zu gehe ich einfach nur spazieren in der Pause und hole mir später etwas Kleines.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Wenn du etwas mitbringst',
        phrases: [
          'Ich nehme meistens ein Sandwich oder Salat mit. Das ist schnell vorbereitet.',
          'Ich koche am Abend mehr, damit ich am nächsten Tag etwas dabei habe.',
          'Ich esse lieber etwas Selbstgemachtes, dann weiß ich, was drin ist.',
          'Das spart Geld und ist oft gesünder.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Wenn du über deine Pause allgemein sprichst',
        phrases: [
          'Für mich ist die Mittagspause wichtig, um kurz abzuschalten.',
          'Ich versuche, in der Pause kurz an die frische Luft zu gehen.',
          'Es ist gut, sich mal vom Schreibtisch zu entfernen.',
          'Manchmal nutze ich die Zeit auch, um kurz private Dinge zu erledigen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st3',
    number: 3,
    stimulus: 'Der Chef möchte, dass ich einen Computerkurs mache. Weißt du, wie ich das organisieren kann?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hm, ich glaube, du solltest zuerst mit der Personalabteilung sprechen. Die wissen oft, welche Kurse angeboten werden.'),
      DialogLine(isPersonA: true, text: 'Gute Idee. Und vielleicht kann ich auch fragen, ob der Kurs während der Arbeitszeit möglich ist.'),
      DialogLine(isPersonA: false, text: 'Ja, oder ob der Betrieb die Kosten übernimmt. Manchmal gibt es auch Online-Kurse, die man flexibel machen kann.'),
      DialogLine(isPersonA: true, text: 'Stimmt, das wäre praktisch. Ich arbeite gern am Computer, aber bei manchen Programmen bin ich noch unsicher.'),
      DialogLine(isPersonA: false, text: 'Dann ist so ein Kurs auf jeden Fall eine gute Chance. Frag einfach mal nach den Möglichkeiten – bestimmt findet sich was Passendes.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Sätze',
        phrases: [
          'Ich weiß nicht, wo ich anfangen soll. Vielleicht sollte ich online suchen?',
          'Kennst du jemanden, der schon so einen Kurs gemacht hat?',
          'Ich hoffe, dass der Kurs mir bei der Arbeit wirklich hilft.',
          'Ich frage mal meine Kollegin, sie hat neulich auch eine Fortbildung gemacht.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st4',
    number: 4,
    stimulus: 'Im Sommer fahre ich gerne an einen See zum Baden. Du auch oder magst du Freibäder lieber?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich gehe auch lieber an einen See. Die Natur ist einfach schöner, und es ist ruhiger als im Freibad.'),
      DialogLine(isPersonA: true, text: 'Ja, genau! Ich mag es, wenn man auf der Wiese liegen kann und es ein bisschen schattig ist.'),
      DialogLine(isPersonA: false, text: 'Und man kann oft auch picknicken oder spazieren gehen. Das ist entspannter als im Schwimmbad.'),
      DialogLine(isPersonA: true, text: 'Stimmt. Und manchmal nehme ich sogar mein Buch mit und bleibe den ganzen Nachmittag dort.'),
      DialogLine(isPersonA: false, text: 'Das klingt schön. Welcher See ist in deiner Nähe?'),
      DialogLine(isPersonA: true, text: 'Ich fahre oft zum [Name einsetzen]. Und du?'),
      DialogLine(isPersonA: false, text: 'Ich kenne einen kleinen See außerhalb der Stadt. Da ist es nicht so voll.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Antworten',
        phrases: [
          'Ich mag Freibäder nur, wenn sie nicht zu voll sind.',
          'Am See fühlt es sich fast wie Urlaub an.',
          'Ich schwimme gern, aber ich bleibe auch einfach gern in der Sonne liegen.',
          'Ich finde es toll, wenn man am See auch grillen darf.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st5',
    number: 5,
    stimulus: 'Wie und wann buchst du deinen Urlaub?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich buche meistens früh, so drei bis vier Monate vorher. Dann sind die Preise günstiger.'),
      DialogLine(isPersonA: true, text: 'Ja, das habe ich auch gemerkt. Ich schaue oft im Internet nach Angeboten, zum Beispiel auf Reiseportalen.'),
      DialogLine(isPersonA: false, text: 'Ich auch. Manchmal vergleiche ich die Preise und buche dann direkt online. Wo machst du gern Urlaub?'),
      DialogLine(isPersonA: true, text: 'Ich mag das Meer, also fahre ich oft im Sommer ans Wasser – zum Beispiel nach Italien oder Kroatien.'),
      DialogLine(isPersonA: false, text: 'Klingt schön! Ich mache auch gern Urlaub am Meer, aber manchmal bleibe ich einfach in Deutschland und mache einen Kurzurlaub.'),
      DialogLine(isPersonA: true, text: 'Das ist auch eine gute Idee. Es gibt hier so viele schöne Orte, die man oft gar nicht kennt.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Sätze',
        phrases: [
          'Ich warte manchmal auf Last-Minute-Angebote.',
          'Ich buche lieber online als im Reisebüro.',
          'Wenn ich frei bekomme, plane ich sofort.',
          'Ich reise lieber im Frühling oder Herbst – da ist es nicht so heiß.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st6',
    number: 6,
    stimulus: 'Ich habe noch fünf Tage Resturlaub. Was passiert mit diesen Tagen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Wenn du die Tage bis Ende März vom nächsten Jahr nicht nimmst, verfallen sie meistens. Du solltest sie am besten bald einplanen.'),
      DialogLine(isPersonA: true, text: 'Oh, das wusste ich nicht genau. Muss ich dafür extra einen Antrag stellen?'),
      DialogLine(isPersonA: false, text: 'Ja, du musst den Urlaubsantrag einreichen und mit deinem Team oder Chef absprechen, wann es passt. Aber wenn keine betrieblichen Gründe dagegen sprechen, darfst du den Urlaub nehmen.'),
      DialogLine(isPersonA: true, text: 'Gut zu wissen. Ich denke, ich nehme die Tage im Herbst. Dann ist es nicht so voll überall.'),
      DialogLine(isPersonA: false, text: 'Klingt gut! Und fünf Tage am Stück sind perfekt für einen kleinen Urlaub oder einfach mal zum Ausruhen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternativen',
        phrases: [
          'Ich muss noch mit meinem Vorgesetzten sprechen, wann es am besten passt.',
          'Ich hoffe, dass ich die Tage bald nehmen kann. Ich brauche mal eine Pause.',
          'Ich wusste gar nicht, dass Urlaubstage verfallen können.',
          'Vielleicht nehme ich ein verlängertes Wochenende.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st7',
    number: 7,
    stimulus: 'Ich arbeite im Homeoffice. Ich habe kein Diensthandy bekommen. Denkst du, dass ich mein Privathandy benutzen soll?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hm, schwierig. Eigentlich solltest du dein Privathandy nicht für die Arbeit benutzen. Es geht ja auch um Datenschutz.'),
      DialogLine(isPersonA: true, text: 'Ja, genau. Ich finde es auch nicht gut, wenn private und berufliche Dinge gemischt werden.'),
      DialogLine(isPersonA: false, text: 'Vielleicht kannst du mit deinem Vorgesetzten sprechen und fragen, ob du ein Diensthandy bekommst – oder ob es eine andere Lösung gibt, zum Beispiel ein Dienst-Tablet oder eine App mit geschütztem Zugang.'),
      DialogLine(isPersonA: true, text: 'Das ist eine gute Idee. Ich will erreichbar sein, aber trotzdem meine privaten Daten schützen.'),
      DialogLine(isPersonA: false, text: 'Genau. Man muss auch mal abschalten können – vor allem, wenn man im Homeoffice arbeitet.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Sätze',
        phrases: [
          'Ich finde, die Firma sollte für die Arbeitsmittel sorgen.',
          'Manche Kollegen benutzen ihr Privathandy, aber ich bin da unsicher.',
          'Ich habe Angst, dass berufliche Kontakte auf meinem privaten Handy gespeichert werden.',
          'Ich telefoniere lieber am Computer mit Headset – das geht auch.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st8',
    number: 8,
    stimulus: 'Der Chef möchte von Mitarbeitern die Arbeitsunfähigkeitsbescheinigung ab dem ersten Tag und nicht am dritten Tag. Was hältst du davon?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hm, ehrlich gesagt finde ich das ein bisschen übertrieben. Manchmal ist man nur einen Tag erkältet oder hat Kopfschmerzen – dafür gleich zum Arzt zu gehen, ist doch unnötig.'),
      DialogLine(isPersonA: true, text: 'Genau. Und wenn man wirklich krank ist, braucht man Ruhe – nicht Stress wegen eines Attests.'),
      DialogLine(isPersonA: false, text: 'Außerdem ist es für die Arztpraxen auch eine Belastung. Viele Patienten kommen nur für den „gelben Schein", obwohl sie sich selbst auskurieren könnten.'),
      DialogLine(isPersonA: true, text: 'Ich verstehe zwar, dass der Chef sicher sein will, dass niemand die Krankheit nur vortäuscht, aber ein bisschen Vertrauen sollte schon da sein.'),
      DialogLine(isPersonA: false, text: 'Ja, finde ich auch. Vielleicht könnte man es nur bei häufigen Krankmeldungen ab dem ersten Tag verlangen – aber nicht grundsätzlich bei jedem Mitarbeiter.'),
      DialogLine(isPersonA: true, text: 'Das wäre fairer. Ich denke, es kommt auf das Arbeitsklima an. Wenn die Mitarbeiter sich respektiert fühlen, wird das System auch nicht ausgenutzt.'),
      DialogLine(isPersonA: false, text: 'Stimmt. Vertrauen ist wichtig – und kranke Menschen sollten sich nicht unter Druck fühlen, sofort zum Arzt zu rennen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternativen & hilfreiche Sätze',
        phrases: [
          'Ich denke, das ist situationsabhängig.',
          'Für einen Tag zu Hause braucht man nicht immer gleich ein Attest.',
          'Ich verstehe den Wunsch nach Kontrolle, aber Gesundheit geht vor.',
          'Vielleicht kann man eine flexible Lösung finden.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st9',
    number: 9,
    stimulus: 'Am Samstag ist der Tag der Offenen Tür im Unternehmen. Wir können unsere Kinder mitbringen. Bist du dabei?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, ich habe davon gehört. Ich finde die Idee super! Ich denke, ich komme auch – vielleicht mit meiner Familie.'),
      DialogLine(isPersonA: true, text: 'Ich bringe meine Tochter mit. Sie ist schon ganz neugierig, wo ich arbeite.'),
      DialogLine(isPersonA: false, text: 'Das ist eine schöne Gelegenheit, den Kindern unseren Arbeitsplatz zu zeigen. Und es gibt ja auch ein kleines Programm für Familien, oder?'),
      DialogLine(isPersonA: true, text: 'Ja, es soll Führungen, Essen und sogar ein paar Spiele für Kinder geben. Ich finde es toll, dass das Unternehmen so etwas organisiert.'),
      DialogLine(isPersonA: false, text: 'Absolut. Es ist auch eine gute Möglichkeit, Kollegen mal privat kennenzulernen.'),
      DialogLine(isPersonA: true, text: 'Genau! Ich freue mich schon drauf. Dann sehen wir uns am Samstag?'),
      DialogLine(isPersonA: false, text: 'Auf jeden Fall. Bis dann!'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Sätze',
        phrases: [
          'Ich finde solche Veranstaltungen stärken das Teamgefühl.',
          'Ich bin gespannt, wie es wird – meine Kinder freuen sich schon.',
          'Vielleicht bringe ich auch meine Frau / meinen Mann mit.',
          'Ich finde es schön, wenn Arbeit und Familie mal zusammenkommen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st10',
    number: 10,
    stimulus: 'Das Unternehmen gewährt keine Boni für dieses Jahr. Was hältst du davon?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ehrlich gesagt, bin ich etwas enttäuscht. Viele von uns haben hart gearbeitet, und ein Bonus wäre eine schöne Anerkennung gewesen.'),
      DialogLine(isPersonA: true, text: 'Ja, finde ich auch. Vor allem, wenn die Firma trotzdem gute Zahlen schreibt – dann versteht man es noch weniger.'),
      DialogLine(isPersonA: false, text: 'Genau. Ich denke, auch kleine Boni motivieren die Mitarbeiter. Es geht nicht nur ums Geld, sondern auch um Wertschätzung.'),
      DialogLine(isPersonA: true, text: 'Vielleicht gibt es stattdessen andere Formen der Anerkennung, zum Beispiel zusätzliche freie Tage oder Gutscheine?'),
      DialogLine(isPersonA: false, text: 'Das wäre wenigstens ein Kompromiss. Aber wenn gar nichts kommt, fühlen sich viele vielleicht nicht genug gesehen.'),
      DialogLine(isPersonA: true, text: 'Ich hoffe, dass es nur für dieses Jahr ist und sich die Situation nächstes Jahr verbessert.'),
      DialogLine(isPersonA: false, text: 'Ja, ich denke, man sollte offen mit der Geschäftsleitung sprechen, damit sie weiß, wie wichtig das Thema für viele ist.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Sätze',
        phrases: [
          'Ich verstehe, wenn das Unternehmen sparen muss, aber eine kleine Anerkennung wäre trotzdem gut gewesen.',
          'Ich finde, gute Arbeit sollte auch belohnt werden.',
          'Man muss die Mitarbeitenden motivieren – auch in schwierigen Zeiten.',
          'Vielleicht könnte man das im nächsten Mitarbeitergespräch ansprechen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st11',
    number: 11,
    stimulus: '80% der Mitarbeiter kommen mit dem Fahrrad zu Arbeit. Findest du es auch toll?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, ich finde das super! Das ist gut für die Gesundheit – und natürlich auch für die Umwelt.'),
      DialogLine(isPersonA: true, text: 'Genau! Und man spart sich den Stress im Berufsverkehr. Ich fahre auch oft mit dem Fahrrad, wenn das Wetter mitmacht.'),
      DialogLine(isPersonA: false, text: 'Ich auch. Und mit den neuen Fahrradständern vor dem Gebäude ist es jetzt viel praktischer.'),
      DialogLine(isPersonA: true, text: 'Stimmt. Ich finde auch, dass das Unternehmen solche nachhaltigen Lösungen mehr unterstützen sollte – vielleicht sogar mit Zuschüssen für E-Bikes?'),
      DialogLine(isPersonA: false, text: 'Gute Idee! Oder mit Umkleideräumen und Duschen für die, die von weiter herkommen. Dann würden vielleicht noch mehr Leute aufs Rad umsteigen.'),
      DialogLine(isPersonA: true, text: 'Ja, und es macht einfach gute Laune, wenn man morgens an der frischen Luft unterwegs ist.'),
      DialogLine(isPersonA: false, text: 'Total! Und Bewegung vor der Arbeit tut einfach gut.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Sätze',
        phrases: [
          'Ich finde das ein gutes Zeichen für ein modernes und umweltbewusstes Unternehmen.',
          'Vielleicht könnten wir auch einen „Fahrrad-Tag" organisieren.',
          'Ich wünsche mir mehr sichere Fahrradwege in der Stadt.',
          'Ich fahre auch im Winter – mit warmer Kleidung und Licht geht das gut.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st12',
    number: 12,
    stimulus: 'Im Dezember gibt es Urlaubssperre. Findest du das fair?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hm, das kommt drauf an. Wenn im Dezember viel los ist, zum Beispiel im Verkauf oder in der Produktion, kann ich das verstehen.'),
      DialogLine(isPersonA: true, text: 'Ja, das stimmt. Aber für viele ist es auch die einzige Zeit, in der die Familie zusammenkommt – gerade zu Weihnachten.'),
      DialogLine(isPersonA: false, text: 'Genau. Ich finde, man sollte wenigstens ein paar Tage freinehmen dürfen, wenn es gut geplant ist. Eine komplette Sperre ist schon streng.'),
      DialogLine(isPersonA: true, text: 'Vielleicht könnte man eine Lösung finden, zum Beispiel mit einem rotierenden System – damit nicht alle gleichzeitig Urlaub nehmen.'),
      DialogLine(isPersonA: false, text: 'Das wäre fairer. Dann hätte jeder eine Chance auf ein paar freie Tage im Dezember.'),
      DialogLine(isPersonA: true, text: 'Ich hoffe, dass die Firma ein bisschen flexibel bleibt. Gerade wenn man Kinder hat, ist die Zeit sehr wichtig.'),
      DialogLine(isPersonA: false, text: 'Absolut. Vielleicht sollten wir das im Team mal ansprechen und gemeinsam eine Lösung vorschlagen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Nützliche Alternativen',
        phrases: [
          'Ich verstehe, dass der Betrieb funktionieren muss, aber etwas Flexibilität wäre gut.',
          'Ich finde eine komplette Urlaubssperre schwierig – besonders rund um Weihnachten.',
          'Vielleicht könnten Ausnahmen gemacht werden – zum Beispiel bei familiären Gründen.',
          'Man könnte frühzeitig planen und die Arbeit im Team aufteilen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st13',
    number: 13,
    stimulus: 'Wo verbringst du am liebsten deine Mittagspause? Ich verbringe sie gerne außerhalb des Betriebs.',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das klingt gut. Ich gehe auch gern mal raus, einfach um frische Luft zu schnappen oder kurz spazieren zu gehen.'),
      DialogLine(isPersonA: true, text: 'Ja, das tut richtig gut – vor allem, wenn man den ganzen Vormittag am Schreibtisch sitzt.'),
      DialogLine(isPersonA: false, text: 'Stimmt. Manchmal hole ich mir etwas beim Bäcker und setze mich auf eine Bank in der Nähe. Das ist entspannter als in der Kantine.'),
      DialogLine(isPersonA: true, text: 'Genau! Ich finde, so kann man besser abschalten und neue Energie für den Nachmittag tanken.'),
      DialogLine(isPersonA: false, text: 'Und wenn das Wetter schön ist, ist es einfach perfekt draußen. Ich finde, jeder sollte die Pause wirklich nutzen – nicht am Arbeitsplatz bleiben.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternativen',
        phrases: [
          'Ich finde es wichtig, in der Pause wirklich abzuschalten.',
          'Ich brauche einfach ein bisschen frische Luft.',
          'Ich gehe oft mit Kolleg*innen nach draußen – das ist auch gut fürs Team.',
          'Wenn das Wetter schlecht ist, bleibe ich manchmal drinnen und lese ein bisschen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st14',
    number: 14,
    stimulus: 'Arbeitest du bevorzugt im Büro oder lieber von zu Hause aus?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Gute Frage. Ich arbeite gern im Homeoffice, weil ich dort konzentrierter bin. Aber manchmal fehlt mir der direkte Kontakt zu den Kolleg*innen.'),
      DialogLine(isPersonA: true, text: 'Ja, das kenne ich. Zu Hause ist es oft ruhiger, aber im Büro hat man schneller Austausch und fühlt sich mehr im Team.'),
      DialogLine(isPersonA: false, text: 'Genau. Ich finde eine Mischung ideal – zum Beispiel zwei Tage im Homeoffice und drei im Büro.'),
      DialogLine(isPersonA: true, text: 'Das wäre auch für mich perfekt. So hat man Flexibilität und bleibt trotzdem verbunden mit dem Team.'),
      DialogLine(isPersonA: false, text: 'Und für Meetings oder kreative Aufgaben ist das Büro oft besser, finde ich.'),
      DialogLine(isPersonA: true, text: 'Stimmt. Und manchmal ist es auch gut, einfach die Wohnung zu verlassen und in den Arbeitsmodus zu kommen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Sätze',
        phrases: [
          'Im Homeoffice spare ich viel Zeit, weil ich nicht pendeln muss.',
          'Im Büro ist der Kontakt mit Kolleg*innen besser.',
          'Zu Hause kann ich flexibler arbeiten, aber ich brauche auch klare Strukturen.',
          'Ich denke, beides hat Vorteile – je nach Aufgabe und Stimmung.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st15',
    number: 15,
    stimulus: 'Ich bevorzuge, im Herbst Urlaub zu nehmen, weil es viele Vorteile hat. Und du? Wann machst du Urlaub?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich mache meistens im Sommer Urlaub, weil ich gern ans Meer fahre und das warme Wetter mag. Aber Herbsturlaub klingt auch gut.'),
      DialogLine(isPersonA: true, text: 'Ja, im Herbst ist es ruhiger und oft günstiger. Es gibt weniger Touristen, und das Klima ist angenehmer – nicht zu heiß.'),
      DialogLine(isPersonA: false, text: 'Das stimmt. Man kann besser entspannen, wenn es nicht so voll ist. Außerdem ist es im Büro oft einfacher, im Herbst frei zu bekommen.'),
      DialogLine(isPersonA: true, text: 'Genau. Und wenn man wandern möchte oder Städtereisen plant, ist es ideal. Ich mag auch die Herbstfarben – alles sieht so schön aus.'),
      DialogLine(isPersonA: false, text: 'Klingt toll! Vielleicht probiere ich das nächstes Jahr auch mal aus.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Nützliche Alternativen',
        phrases: [
          'Im Herbst sind die Preise oft niedriger.',
          'Ich finde, der Herbst ist ideal, um neue Energie zu tanken.',
          'Ich mag keine große Hitze, deshalb ist der Herbst perfekt für mich.',
          'Ich reise gern in der Nebensaison – das ist entspannter.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st16',
    number: 16,
    stimulus: 'Ich würde gerne in meiner Freizeit ehrenamtlich arbeiten. Hast du eine Idee, was man machen könnte?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das finde ich toll! Es gibt viele Möglichkeiten. Du könntest zum Beispiel im Seniorenheim helfen oder Kinder bei den Hausaufgaben unterstützen.'),
      DialogLine(isPersonA: true, text: 'Das klingt gut. Ich mag es, mit Menschen zu arbeiten. Vielleicht auch in einer Suppenküche oder bei der Tafel?'),
      DialogLine(isPersonA: false, text: 'Ja, genau! Oder in einem Tierheim, wenn du Tiere magst. Da wird auch oft Hilfe gesucht – zum Beispiel beim Gassigehen oder Füttern.'),
      DialogLine(isPersonA: true, text: 'Stimmt, das wäre auch schön. Ich denke, ehrenamtliche Arbeit ist wichtig – man hilft anderen und bekommt viel zurück.'),
      DialogLine(isPersonA: false, text: 'Absolut. Außerdem lernt man neue Leute kennen und sammelt wertvolle Erfahrungen.'),
      DialogLine(isPersonA: true, text: 'Ich werde mal schauen, was es in meiner Stadt gibt. Vielleicht starte ich bald damit.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternativen',
        phrases: [
          'Ich finde es wichtig, etwas Gutes für die Gesellschaft zu tun.',
          'Ehrenamt ist eine schöne Möglichkeit, die Freizeit sinnvoll zu nutzen.',
          'Ich interessiere mich für soziale Projekte oder Umweltaktionen.',
          'Vielleicht frage ich mal im Rathaus oder bei der Freiwilligenbörse nach.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st17',
    number: 17,
    stimulus: 'Ich habe nächste Woche meine erste Nachtschicht. Was machst du, um wach zu bleiben?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Oh, Nachtschicht kann am Anfang ganz schön anstrengend sein! Ich trinke ab und zu einen Kaffee, aber nicht zu viel, sonst kann ich morgens nicht schlafen.'),
      DialogLine(isPersonA: true, text: 'Ja, das habe ich auch gehört. Ich überlege, mir ein paar gesunde Snacks mitzunehmen, vielleicht Nüsse oder Obst.'),
      DialogLine(isPersonA: false, text: 'Das ist eine gute Idee. Und ich mache auch manchmal kurze Bewegungspausen – ein bisschen dehnen oder frische Luft schnappen, das hilft gegen Müdigkeit.'),
      DialogLine(isPersonA: true, text: 'Klingt gut! Und wie bereitest du dich auf die Nachtschicht vor?'),
      DialogLine(isPersonA: false, text: 'Ich schlafe vorher ein paar Stunden am Nachmittag. Und ich versuche, mein Handy vor der Schicht nicht zu viel zu benutzen, damit ich später konzentriert bin.'),
      DialogLine(isPersonA: true, text: 'Danke, das sind echt hilfreiche Tipps! Ich bin gespannt, wie es wird.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative 2 – Ernährung & Bewegung',
        phrases: ['Ich esse lieber leichte, gesunde Snacks statt Fast Food – das macht nicht so müde. Und wenn ich merke, dass ich müde werde, laufe ich kurz draußen oder mache ein paar Schritte im Flur.'],
      ),
      SmalltalkAlternatives(
        label: 'Alternative 3 – Vorbereitung & Schlaf',
        phrases: ['Ich schlafe vorher ein paar Stunden am Nachmittag. Wenn ich gut ausgeruht bin, fällt mir die Nachtschicht leichter. Und ich bereite alles am Abend vorher vor – das nimmt Stress.'],
      ),
      SmalltalkAlternatives(
        label: 'Alternative 4 – Musik & Kollegen',
        phrases: ['Ich höre manchmal leise Musik oder Podcasts, wenn das erlaubt ist. Und mit netten Kollegen geht die Zeit schneller vorbei – ein kurzes Gespräch hält auch wach.'],
      ),
      SmalltalkAlternatives(
        label: 'Alternative 5 – Licht & Umgebung',
        phrases: ['Ich achte auf helles Licht im Arbeitsraum – das hilft meinem Körper, wach zu bleiben. Ich vermeide dunkle, ruhige Räume, weil ich sonst schnell müde werde.'],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st18',
    number: 18,
    stimulus: 'Bist du auch produktiver in der Frühschicht? Das trifft auf mich zu.',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das kenne ich! Morgens bin ich meistens konzentrierter und habe mehr Energie. Nachmittags werde ich schneller müde.'),
      DialogLine(isPersonA: true, text: 'Genau! Und es ist schön, wenn man schon früh viel erledigt hat. Danach ist der Tag irgendwie entspannter.'),
      DialogLine(isPersonA: false, text: 'Stimmt. Und in der Früh ist es oft ruhiger im Betrieb, da kann man besser arbeiten. Außerdem bleibt nach Feierabend noch genug Zeit für sich selbst.'),
      DialogLine(isPersonA: true, text: 'Ja, das ist auch ein großer Vorteil. Ich nutze die Zeit nach der Arbeit gerne für Sport oder zum Einkaufen.'),
      DialogLine(isPersonA: false, text: 'Ich auch – oder einfach zum Abschalten. Ich bin auf jeden Fall ein Frühaufsteher!'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Antwort 1 – Zustimmung & Begründung',
        phrases: ['Ja, das geht mir genauso. Morgens bin ich einfach viel frischer und konzentrierter. Ich schaffe in den ersten Stunden oft mehr als am ganzen Nachmittag.'],
      ),
      SmalltalkAlternatives(
        label: 'Antwort 2 – Zustimmung mit Fokus auf Arbeitsumfeld',
        phrases: ['Ich finde auch, dass man in der Früh besser arbeiten kann. Es ist noch ruhig im Büro und man wird nicht so oft gestört.'],
      ),
      SmalltalkAlternatives(
        label: 'Antwort 3 – Teilweise Zustimmung',
        phrases: ['Manchmal schon, aber nur wenn ich gut geschlafen habe. Wenn ich zu müde bin, brauche ich erst mal einen Kaffee und etwas Zeit, um richtig anzukommen.'],
      ),
      SmalltalkAlternatives(
        label: 'Antwort 4 – Gegenmeinung',
        phrases: ['Ehrlich gesagt nicht. Ich bin eher ein Abendmensch. In der Spätschicht bin ich wacher und kreativer. Die Frühschicht fällt mir schwer.'],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st19',
    number: 19,
    stimulus: 'Brauchst du nach der Arbeit auch erstmal Ruhe, wie ich? Ich merke, dass ich ohne eine Pause am Abend kaum abschalten kann.',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das kenne ich gut! Ich setze mich meistens erstmal mit einem Tee aufs Sofa und mache gar nichts. Manchmal höre ich auch einfach nur Musik.'),
      DialogLine(isPersonA: true, text: 'Das klingt gut. Ich mache mir oft eine Kleinigkeit zu essen und lasse den Tag einfach ruhig ausklingen.'),
      DialogLine(isPersonA: false, text: 'Genau, wenn man den ganzen Tag konzentriert gearbeitet hat, braucht der Kopf einfach eine Pause. Danach fühle ich mich auch wieder fitter.'),
      DialogLine(isPersonA: true, text: 'Stimmt. Ohne diese Ruhezeit wäre ich abends echt nicht mehr zu gebrauchen!'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ja, das brauche ich auch. Ich bin nach der Arbeit oft richtig erschöpft.',
          'Auf jeden Fall. Ich brauche erstmal Zeit, um runterzukommen.',
          'Ich finde es wichtig, nach der Arbeit etwas für sich selbst zu tun.',
          'Ohne eine Pause könnte ich abends nichts mehr machen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Teilweise Zustimmung',
        phrases: [
          'Kommt drauf an. Wenn es ein stressiger Tag war, auf jeden Fall.',
          'Manchmal ja, aber oft gehe ich gleich noch einkaufen oder spazieren.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Gegenmeinung',
        phrases: [
          'Nicht unbedingt. Ich brauche eher Bewegung, um abzuschalten.',
          'Ich entspanne mich besser, wenn ich nach der Arbeit noch etwas unternehme.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Nützliche Wendungen allgemein',
        phrases: [
          'Ich merke, dass …',
          'Ich finde es wichtig, …',
          'Das hilft mir, …',
          'So kann ich … besser …',
          'Ich mache das meistens so, dass …',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st20',
    number: 20,
    stimulus: 'Sollen wir mittags etwas bestellen? Wie wäre es mit einem gemeinsamen Mittagessen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Gern, das klingt gut. Ich habe heute nichts dabei, also wäre das perfekt.'),
      DialogLine(isPersonA: true, text: 'Super! Ich hätte Lust auf Pizza oder vielleicht etwas Asiatisches. Was meinst du?'),
      DialogLine(isPersonA: false, text: 'Pizza wäre super! Die vom Italiener hier in der Nähe ist richtig lecker.'),
      DialogLine(isPersonA: true, text: 'Dann bestelle ich gleich. Sollen wir im Pausenraum essen?'),
      DialogLine(isPersonA: false, text: 'Ja, gerne. Dann machen wir eine entspannte Mittagspause zusammen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmend',
        phrases: [
          'Ja, gerne! Ich habe auch keine Lust, alleine zu essen.',
          'Gute Idee – gemeinsam schmeckt es besser!',
          'Klar, das wäre eine schöne Pause.',
          'Warum nicht? Ich bin dabei!',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral/zurückhaltend',
        phrases: [
          'Hm, ich weiß noch nicht genau. Vielleicht später?',
          'Ich muss schauen, ob ich Zeit habe, aber klingt gut.',
          'Können wir spontan entscheiden? Ich habe gleich noch einen Anruf.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Ablehnend',
        phrases: [
          'Danke, aber ich habe schon etwas dabei.',
          'Heute lieber nicht, ich muss in der Pause etwas erledigen.',
          'Ich esse heute schnell am Platz, aber vielleicht morgen?',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st21',
    number: 21,
    stimulus: 'Nächsten Monat kann ich leider keine Überstunden machen. Denkst du, dass es geht?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das kann ich gut verstehen. Wenn du rechtzeitig Bescheid gibst, sollte das eigentlich kein Problem sein.'),
      DialogLine(isPersonA: true, text: 'Ich habe ein paar private Termine, die ich nicht verschieben kann.'),
      DialogLine(isPersonA: false, text: 'Vielleicht kannst du ja im Voraus etwas mehr schaffen, damit der Chef sieht, dass du trotzdem zuverlässig bist.'),
      DialogLine(isPersonA: true, text: 'Gute Idee. Ich spreche am besten direkt mit ihm.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmend',
        phrases: [
          'Klar, jeder hat mal so eine Phase. Sag einfach rechtzeitig Bescheid.',
          'Das verstehe ich total. Ich glaube, der Chef hat da bestimmt Verständnis.',
          'Wenn du es vorher absprichst, sollte das kein Problem sein.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral/zurückhaltend',
        phrases: [
          'Kommt darauf an, wie viel los ist. Aber versuchen kannst du es.',
          'Vielleicht musst du dann trotzdem bei Engpässen einspringen.',
          'Ich denke, es geht, aber du solltest das wirklich mit der Teamleitung klären.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritisch',
        phrases: [
          'Wenn gerade viel zu tun ist, wird das schwierig.',
          'Dann müssen die anderen vielleicht mehr übernehmen – das könnte stressig werden.',
          'Der Chef sieht das vielleicht nicht so gern, aber man kann es versuchen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st22',
    number: 22,
    stimulus: 'Meine neue Kollegin ist leider ziemlich unfreundlich. Hast du vielleicht einen Tipp, wie ich damit umgehen kann?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Oh, das ist unangenehm. Vielleicht hilft es, wenn du versuchst, in Ruhe mit ihr zu reden?'),
      DialogLine(isPersonA: true, text: 'Ich habe überlegt, sie einfach direkt, aber freundlich anzusprechen.'),
      DialogLine(isPersonA: false, text: 'Das ist ein guter Ansatz. Oft merkt die andere Person gar nicht, wie sie wirkt. Oder du sprichst erstmal mit jemandem aus dem Team, ob sie dieselbe Erfahrung gemacht haben.'),
      DialogLine(isPersonA: true, text: 'Stimmt, vielleicht geht es nicht nur mir so. Danke für den Tipp!'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Ratsam und verständnisvoll',
        phrases: [
          'Vielleicht ist sie am Anfang einfach nur unsicher.',
          'Gib ihr ein bisschen Zeit – manche brauchen länger, um warm zu werden.',
          'Ein direktes, ruhiges Gespräch wirkt oft Wunder.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral/zurückhaltend',
        phrases: [
          'Manchmal hilft es auch, einfach höflich zu bleiben und Abstand zu halten.',
          'Ich würde erstmal beobachten, ob sich das legt.',
          'Vielleicht klärt sich das von selbst mit der Zeit.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritisch oder vorsichtig',
        phrases: [
          'Wenn es gar nicht besser wird, solltest du mit der Teamleitung reden.',
          'So ein Verhalten kann das Arbeitsklima echt stören.',
          'Unfreundlichkeit am Arbeitsplatz geht eigentlich gar nicht.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st23',
    number: 23,
    stimulus: 'Ich soll am Samstag für eine Kollegin einspringen. Weißt du, ich bekomme dafür nächste Woche einen anderen Tag frei.',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ach so, das ist ja fair von der Firma, dass sie dir einen Ersatztag gibt. Findest du das eine gute Lösung?'),
      DialogLine(isPersonA: true, text: 'Ja, grundsätzlich schon. Aber Samstag arbeiten finde ich trotzdem nicht so toll – gerade, wenn man Pläne hat oder einfach mal entspannen will.'),
      DialogLine(isPersonA: false, text: 'Das kann ich verstehen. Aber immerhin kannst du den freien Tag flexibel nutzen, oder?'),
      DialogLine(isPersonA: true, text: 'Genau. Ich werde mir wahrscheinlich den Freitag danach freinehmen und ein langes Wochenende machen.'),
      DialogLine(isPersonA: false, text: 'Das klingt doch super! Manchmal muss man eben Kompromisse machen.'),
      DialogLine(isPersonA: true, text: 'Stimmt. Ich hoffe nur, dass ich am Samstag nicht zu müde werde. Das ist ja doch ein anderer Rhythmus.'),
      DialogLine(isPersonA: false, text: 'Vielleicht kannst du dich vorher gut ausruhen und die Woche über etwas langsamer machen.'),
      DialogLine(isPersonA: true, text: 'Ja, das mache ich. Danke für die Tipps!'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Das ist ja gut, dass du einen Ausgleich bekommst.',
          'Ich finde es fair, wenn man dafür einen Ersatztag bekommt.',
          'So kann man besser planen und die Arbeit wird gerecht verteilt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Manchmal geht das eben nicht anders.',
          'Wichtig ist, dass du den freien Tag auch wirklich bekommst.',
          'Ich hoffe, es ist nicht zu stressig für dich.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik',
        phrases: [
          'Samstag arbeiten ist trotzdem blöd, finde ich.',
          'Ich würde ungern an einem Wochenende arbeiten.',
          'Das macht das Privatleben oft komplizierter.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st24',
    number: 24,
    stimulus: 'Mein Kind weint oft in der Kita, wenn ich es morgens abgebe. Das macht mich total unsicher. Hast du vielleicht Erfahrungen damit? Und Tipps, wie ich damit umgehen kann?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das kenne ich gut. Mein Kind hat am Anfang auch viel geweint. Das ist ganz normal, weil die Kleinen sich erst an die neue Umgebung gewöhnen müssen.'),
      DialogLine(isPersonA: true, text: 'Das beruhigt mich schon ein bisschen. Aber es tut mir so weh, wenn ich es weinen höre.'),
      DialogLine(isPersonA: false, text: 'Verstehe ich total. Mir hat geholfen, immer freundlich und ruhig zu bleiben. Versuche, das Kind nicht zu lange zu trösten, sondern ihm zu zeigen, dass du weggehst, aber wiederkommst.'),
      DialogLine(isPersonA: true, text: 'Ja, meine Erzieherin sagt auch, dass ich konsequent sein soll. Aber das fällt mir schwer.'),
      DialogLine(isPersonA: false, text: 'Es ist schwer, aber Kinder merken deine Sicherheit. Wenn du entspannt bist, fühlt sich das Kind sicherer an.'),
      DialogLine(isPersonA: true, text: 'Ich werde das versuchen. Vielleicht hilft es, wenn ich meinem Kind vorher erzähle, was passiert.'),
      DialogLine(isPersonA: false, text: 'Das ist eine super Idee. Auch kleine Rituale am Morgen können helfen, zum Beispiel ein Abschiedskuss oder ein Lieblingsspielzeug mitgeben.'),
      DialogLine(isPersonA: true, text: 'Danke, das werde ich ausprobieren. Es ist gut, nicht allein damit zu sein.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Ermutigung und Tipps',
        phrases: [
          'Das ist ganz normal am Anfang.',
          'Wichtig ist, dass du ruhig bleibst und Vertrauen zeigst.',
          'Ein festes Abschiedsritual hilft oft.',
          'Manchmal hilft es, das Kind langsam an die Kita zu gewöhnen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutrale Tipps',
        phrases: [
          'Vielleicht hilft es, wenn du eine kurze Zeit mit bleibst und dann gehst.',
          'Frag die Erzieherinnen, wie es deinem Kind geht.',
          'Jedes Kind braucht seine eigene Zeit.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Vorsichtige Hinweise',
        phrases: [
          'Wenn es sehr lange weint, solltest du das mit den Erziehern besprechen.',
          'Manchmal kann auch ein Gespräch mit einem Kinderpsychologen helfen.',
          'Verlass dich auf dein Gefühl, und suche Unterstützung, wenn nötig.',
        ],
      ),
    ],
  ),

  SmalltalkExercise(
    id: 'st25',
    number: 25,
    stimulus: 'Ich möchte meine Kollegen besser kennenlernen. Hast du vielleicht eine Idee, wie ich das machen könnte?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das ist eine gute Idee! Vielleicht könntest du mal ein kleines Treffen oder einen gemeinsamen Kaffee vorschlagen.'),
      DialogLine(isPersonA: true, text: 'Ja, das klingt gut. Ich habe gehört, dass manche Teams auch After-Work-Treffen machen.'),
      DialogLine(isPersonA: false, text: 'Genau, oder man organisiert gemeinsam ein Mittagessen. Das ist locker und man kann sich besser unterhalten.'),
      DialogLine(isPersonA: true, text: 'Was ist, wenn nicht alle mitmachen wollen?'),
      DialogLine(isPersonA: false, text: 'Das passiert manchmal. Wichtig ist, dass du offen und freundlich bleibst. Vielleicht laden dich einige trotzdem ein.'),
      DialogLine(isPersonA: true, text: 'Stimmt. Vielleicht kann ich auch bei der nächsten Teambesprechung ein bisschen Small Talk machen.'),
      DialogLine(isPersonA: false, text: 'Auf jeden Fall! Kleine Gespräche helfen oft, die Hemmschwelle abzubauen.'),
      DialogLine(isPersonA: true, text: 'Danke für die Tipps. Ich werde das mal ausprobieren.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung und Vorschläge',
        phrases: [
          'Ich finde das auch wichtig. Gemeinsame Aktivitäten bringen das Team näher zusammen.',
          'Man kann auch ein Spiel oder eine Teamchallenge vorschlagen.',
          'Kleine Pausen zusammen verbringen, z. B. beim Kaffee, ist oft sehr hilfreich.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Manche Leute sind eher zurückhaltend, aber mit Geduld klappt das bestimmt.',
          'Man muss es langsam angehen und nicht zu viel auf einmal wollen.',
          'Einfach zuhören und Interesse zeigen ist schon ein guter Anfang.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik',
        phrases: [
          'Manche Kollegen sind leider nicht so offen.',
          'Nicht jeder möchte außerhalb der Arbeit Zeit mit Kollegen verbringen.',
          'Das kann manchmal schwierig sein, wenn das Team schon fest ist.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st26',
    number: 26,
    stimulus: 'Ich möchte gerne mal im Sommer Urlaub machen. Leider dürfen das bei uns nur Kolleginnen und Kollegen mit Kindern. Findest du das fair?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hmm, das ist eine schwierige Frage. Ich kann verstehen, dass Eltern im Sommer oft Urlaub brauchen, weil die Schulen geschlossen sind.'),
      DialogLine(isPersonA: true, text: 'Ja, das stimmt. Aber ich finde, dass alle Mitarbeiter die gleichen Chancen auf Sommerurlaub haben sollten.'),
      DialogLine(isPersonA: false, text: 'Da hast du recht. Es wäre besser, wenn die Firma flexibel auf die Bedürfnisse aller eingeht.'),
      DialogLine(isPersonA: true, text: 'Manchmal fühle ich mich etwas benachteiligt, weil ich keine Kinder habe.'),
      DialogLine(isPersonA: false, text: 'Das kann ich verstehen. Vielleicht könntest du mit dem Chef sprechen und deine Situation erklären.'),
      DialogLine(isPersonA: true, text: 'Das ist eine gute Idee. Vielleicht lässt sich eine Lösung finden, die für alle passt.'),
      DialogLine(isPersonA: false, text: 'Genau, offene Gespräche sind oft der beste Weg.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung zur Kritik',
        phrases: [
          'Ich finde auch, dass Urlaub gerecht verteilt werden sollte.',
          'Alle sollten die gleichen Möglichkeiten haben, ihren Urlaub zu planen.',
          'Man kann die Bedürfnisse von Eltern berücksichtigen, aber nicht nur auf sie achten.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Verständnis für Eltern',
        phrases: [
          'Eltern haben im Sommer oft besondere Herausforderungen.',
          'Die Schule und Betreuung sind wichtige Faktoren.',
          'Es ist schwierig, alle zufrieden zu stellen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Verteidigung der Regelung',
        phrases: [
          'Die Firma möchte wohl Familien unterstützen.',
          'Es ist eine übliche Praxis in vielen Betrieben.',
          'Manchmal muss man Prioritäten setzen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st27',
    number: 27,
    stimulus: 'Bei uns in der Firma gibt es eine dreimonatige Kündigungsfrist. Findest du, das ist nicht zu viel?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Dreimonatige Kündigungsfrist klingt erstmal lang. Aber sie gibt auch Sicherheit für beide Seiten, finde ich.'),
      DialogLine(isPersonA: true, text: 'Das stimmt, aber manchmal möchte man doch schneller wechseln, wenn man zum Beispiel einen neuen Job findet.'),
      DialogLine(isPersonA: false, text: 'Ja, das kann frustrierend sein. Aber eine längere Kündigungsfrist gibt dem Arbeitgeber Zeit, Ersatz zu finden.'),
      DialogLine(isPersonA: true, text: 'Das verstehe ich. Andererseits kann es für Arbeitnehmer schwierig sein, so lange zu warten.'),
      DialogLine(isPersonA: false, text: 'Vielleicht gibt es ja Möglichkeiten, mit dem Arbeitgeber eine kürzere Frist zu vereinbaren, wenn beide zustimmen.'),
      DialogLine(isPersonA: true, text: 'Das wäre ideal. Ich werde mal nachfragen, ob so etwas möglich ist.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung zur Kündigungsfrist',
        phrases: [
          'Eine längere Kündigungsfrist sorgt für Planungssicherheit.',
          'So hat die Firma Zeit, eine neue Person einzustellen.',
          'Für beide Seiten ist das oft fair.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral / Vor- und Nachteile',
        phrases: [
          'Es hat Vorteile und Nachteile, je nachdem, wie schnell man wechseln möchte.',
          'Manchmal ist die Kündigungsfrist zu lang, aber sie schützt auch den Arbeitnehmer.',
          'Am besten ist es, wenn man individuell verhandeln kann.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik an der Frist',
        phrases: [
          'Drei Monate sind wirklich lang. Manche Firmen haben nur einen Monat.',
          'Das schränkt die Flexibilität stark ein.',
          'Ich finde, die Frist sollte kürzer sein, damit man schneller reagieren kann.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st28',
    number: 28,
    stimulus: 'Ich würde am Wochenende mit Freunden bei mir im Garten grillen. Magst du auch kommen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das klingt super! Ich liebe Grillen, vor allem draußen im Garten.'),
      DialogLine(isPersonA: true, text: 'Ja, das Wetter soll ja auch schön werden. Wir wollen ein bisschen Musik hören und einfach entspannen.'),
      DialogLine(isPersonA: false, text: 'Das passt perfekt. Soll ich etwas mitbringen? Getränke oder Salate?'),
      DialogLine(isPersonA: true, text: 'Das wäre toll, danke! Vielleicht kannst du einen Salat machen. Ich kümmere mich um das Fleisch und die Getränke.'),
      DialogLine(isPersonA: false, text: 'Super, ich freue mich schon. Um wie viel Uhr soll ich kommen?'),
      DialogLine(isPersonA: true, text: 'Wir starten gegen 16 Uhr. Komm gern etwas früher, dann helfen wir zusammen beim Vorbereiten.'),
      DialogLine(isPersonA: false, text: 'Alles klar, ich bin dabei! Danke für die Einladung.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmend',
        phrases: [
          'Ja, gern! Das hört sich nach einem schönen Nachmittag an.',
          'Danke für die Einladung, ich komme gerne.',
          'Ich bringe etwas zu essen mit, wenn du möchtest.',
          'Grillen im Garten ist immer toll!',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral / vorsichtig',
        phrases: [
          'Ich muss noch schauen, ob ich Zeit habe, aber danke für die Einladung.',
          'Klingt gut, ich gebe dir noch Bescheid.',
          'Vielleicht schaffe ich es, ich melde mich später.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Ablehnend',
        phrases: [
          'Danke, aber ich habe am Wochenende schon etwas vor.',
          'Das ist nett, aber ich mag Grillen nicht so sehr.',
          'Ich bleibe lieber zuhause, aber danke für die Einladung.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st29',
    number: 29,
    stimulus: 'Eine Freundin von mir sagt, dass in ihrer Firma freitags schon um 14 Uhr Feierabend ist. Was hältst du davon?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das klingt echt toll! Ein früher Feierabend am Freitag gibt mehr Zeit fürs Wochenende.'),
      DialogLine(isPersonA: true, text: 'Ja, ich finde das auch sehr angenehm. So kann man das Wochenende besser genießen.'),
      DialogLine(isPersonA: false, text: 'Allerdings könnte es auch bedeuten, dass man von Montag bis Donnerstag mehr arbeiten muss.'),
      DialogLine(isPersonA: true, text: 'Das stimmt. Aber wenn die Gesamtarbeitszeit gleich bleibt, finde ich es fair.'),
      DialogLine(isPersonA: false, text: 'Ich denke, so eine Regelung fördert die Work-Life-Balance und macht die Mitarbeiter zufriedener.'),
      DialogLine(isPersonA: true, text: 'Genau. Vielleicht sollten wir das in unserer Firma auch vorschlagen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ich finde das super. Ein früher Feierabend ist eine tolle Motivation.',
          'Das verbessert die Vereinbarkeit von Arbeit und Freizeit.',
          'So kann man sich besser erholen und ist am Montag wieder produktiver.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Kommt darauf an, wie die Arbeitszeit sonst geregelt ist.',
          'Wenn die Arbeitszeit gleich bleibt, ist das in Ordnung.',
          'Manche mögen es, andere nicht so sehr.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik',
        phrases: [
          'Vielleicht muss man an den anderen Tagen länger arbeiten, das ist dann stressig.',
          'Für manche Jobs ist das wahrscheinlich schwierig umzusetzen.',
          'Das ist nicht für alle Firmen praktikabel.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st30',
    number: 30,
    stimulus: 'Im Unternehmen findet bald ein Seminar zur Stressbewältigung statt. Ich würde es gerne besuchen. Bist du auch dabei?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das klingt interessant! Stressbewältigung ist ja heutzutage sehr wichtig. Ich überlege noch, ob ich mich auch anmelde.'),
      DialogLine(isPersonA: true, text: 'Ich finde, es ist eine gute Gelegenheit, neue Techniken zu lernen und besser mit Stress umzugehen.'),
      DialogLine(isPersonA: false, text: 'Ja, gerade im Job kann man oft ganz schön unter Druck stehen. Hast du schon gehört, was genau im Seminar gemacht wird?'),
      DialogLine(isPersonA: true, text: 'Ja, es gibt verschiedene Übungen zur Entspannung und Tipps für den Alltag. Außerdem soll es auch um Zeitmanagement gehen.'),
      DialogLine(isPersonA: false, text: 'Das klingt wirklich hilfreich. Vielleicht melde ich mich auch an, wenn noch Plätze frei sind.'),
      DialogLine(isPersonA: true, text: 'Super! Dann können wir ja zusammen hingehen und uns gegenseitig unterstützen.'),
      DialogLine(isPersonA: false, text: 'Auf jeden Fall! Es ist immer besser, so etwas nicht allein zu machen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ja, ich finde das Seminar auch wichtig und werde mich anmelden.',
          'Das ist eine gute Gelegenheit, etwas für die Gesundheit zu tun.',
          'Gemeinsam macht das Seminar bestimmt mehr Spaß.',
          'Ich habe auch schon Interesse daran.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Ich bin mir noch nicht sicher, ob das etwas für mich ist.',
          'Vielleicht schaue ich erst mal, wie es läuft.',
          'Ich muss noch schauen, ob ich Zeit habe.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Ablehnung',
        phrases: [
          'Ich glaube, das ist nicht so mein Thema.',
          'Stress habe ich eigentlich nicht so viel.',
          'Ich mache lieber Sport, um abzuschalten.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st31',
    number: 31,
    stimulus: 'Ich arbeite schon lange hier und würde mich gerne weiterentwickeln. Hast du vielleicht Ideen, was ich machen könnte?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das ist eine tolle Einstellung! Hast du schon darüber nachgedacht, einen Weiterbildungskurs oder eine Schulung zu besuchen?'),
      DialogLine(isPersonA: true, text: 'Ja, das habe ich. Aber ich weiß nicht genau, welcher Kurs sinnvoll wäre.'),
      DialogLine(isPersonA: false, text: 'Vielleicht kannst du mit deinem Chef sprechen und fragen, welche Qualifikationen im Unternehmen gerade besonders gefragt sind.'),
      DialogLine(isPersonA: true, text: 'Gute Idee. Außerdem könnte ich mich für neue Projekte oder Aufgaben im Team melden.'),
      DialogLine(isPersonA: false, text: 'Genau! So zeigst du Engagement und kannst neue Fähigkeiten direkt im Job anwenden.'),
      DialogLine(isPersonA: true, text: 'Ich denke auch darüber nach, an einem Coaching teilzunehmen, um meine Führungsqualitäten zu verbessern.'),
      DialogLine(isPersonA: false, text: 'Das klingt super. Manchmal bieten Firmen auch interne Coachings oder Mentoring-Programme an.'),
      DialogLine(isPersonA: true, text: 'Das werde ich mal recherchieren. Danke für die Tipps!'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Vorschläge zur Weiterbildung',
        phrases: [
          'Eine Weiterbildung in deinem Fachgebiet könnte sehr hilfreich sein.',
          'Manchmal gibt es auch Online-Kurse, die flexibel sind.',
          'Es lohnt sich, auch Soft Skills wie Kommunikation oder Zeitmanagement zu trainieren.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Ich weiß nicht genau, was für dich passend wäre.',
          'Vielleicht kannst du dich auch mit Kollegen austauschen und sehen, was sie machen.',
          'Man muss erstmal herausfinden, was einem selbst am meisten hilft.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik / Vorsicht',
        phrases: [
          'Manchmal sind Weiterbildungen sehr teuer oder zeitaufwendig.',
          'Nicht jede Weiterbildung bringt auch wirklich einen Vorteil.',
          'Wichtig ist, dass du es mit deinen Zielen abgleichst.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st32',
    number: 32,
    stimulus: 'Ich brauche ein zusätzliches Einkommen. Denkst du, es ist eine gute Idee, einen Nebenjob anzunehmen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das kann auf jeden Fall helfen, um mehr Geld zu verdienen. Aber es kommt auch darauf an, wie viel Zeit du hast.'),
      DialogLine(isPersonA: true, text: 'Ja, ich mache mir Sorgen, dass ich zu müde werde oder die Arbeit darunter leidet.'),
      DialogLine(isPersonA: false, text: 'Das ist verständlich. Ein Nebenjob sollte gut geplant sein, damit du nicht zu viel Stress bekommst.'),
      DialogLine(isPersonA: true, text: 'Vielleicht wäre ein flexibler Job besser, zum Beispiel am Wochenende oder abends.'),
      DialogLine(isPersonA: false, text: 'Genau, oder etwas, das dir auch Spaß macht, dann fällt es leichter.'),
      DialogLine(isPersonA: true, text: 'Hast du Tipps, wo ich nach solchen Nebenjobs suchen kann?'),
      DialogLine(isPersonA: false, text: 'Ja, du kannst online nach Teilzeitjobs suchen oder dich bei Zeitarbeitsfirmen informieren. Auch im Bekanntenkreis hört man oft von Angeboten.'),
      DialogLine(isPersonA: true, text: 'Danke für die Tipps! Ich werde das mal ausprobieren.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ja, das kann eine gute Lösung sein, um mehr Geld zu verdienen.',
          'Mit einem Nebenjob kann man seine finanzielle Situation verbessern.',
          'Wichtig ist, dass du deine Zeit gut einteilst.',
          'Ein Job, der dir Spaß macht, ist natürlich am besten.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Es kommt wirklich darauf an, wie viel Zeit und Energie du hast.',
          'Manchmal ist ein Nebenjob auch anstrengend.',
          'Vielleicht gibt es auch andere Möglichkeiten, zusätzliches Geld zu verdienen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik / Vorsicht',
        phrases: [
          'Man sollte nicht zu viel arbeiten, sonst wird man schnell ausgebrannt.',
          'Nebenjobs können die Hauptarbeit beeinträchtigen.',
          'Achte darauf, dass du genug Zeit für Erholung hast.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st33',
    number: 33,
    stimulus: 'In der Firma soll es bald Maßnahmen zur betrieblichen Gesundheitsförderung geben. Wie findest du das?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich finde das richtig gut! Gesundheit am Arbeitsplatz ist sehr wichtig.'),
      DialogLine(isPersonA: true, text: 'Ja, gerade bei sitzenden Tätigkeiten kann so etwas helfen, Krankheiten vorzubeugen.'),
      DialogLine(isPersonA: false, text: 'Genau. Vielleicht gibt es ja Kurse für Bewegung oder Entspannung.'),
      DialogLine(isPersonA: true, text: 'Oder Workshops zum Thema Ernährung und Stressmanagement.'),
      DialogLine(isPersonA: false, text: 'Das würde sicher die Motivation und das Wohlbefinden der Mitarbeiter verbessern.'),
      DialogLine(isPersonA: true, text: 'Ich hoffe, die Firma unterstützt das auch finanziell und organisatorisch.'),
      DialogLine(isPersonA: false, text: 'Wenn das gut gemacht wird, profitieren alle davon – sowohl Mitarbeiter als auch Arbeitgeber.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ich finde es sehr wichtig, dass die Firma sich um die Gesundheit der Mitarbeiter kümmert.',
          'Gesundheitsförderung kann Stress reduzieren und die Produktivität steigern.',
          'Das zeigt, dass die Firma die Mitarbeiter wertschätzt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Es kommt darauf an, wie die Maßnahmen umgesetzt werden.',
          'Manche Angebote sind vielleicht nicht für jeden interessant.',
          'Wichtig ist, dass die Mitarbeiter auch wirklich teilnehmen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik',
        phrases: [
          'Manchmal sind solche Maßnahmen nur ein Marketing-Gag.',
          'Wenn es nur Pflichtveranstaltungen sind, macht das wenig Sinn.',
          'Die Firma sollte auch die Arbeitsbedingungen verbessern, nicht nur Workshops anbieten.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st34',
    number: 34,
    stimulus: 'Findest du es auch super, dass in unserer Kantine mehr vegane und vegetarische Gerichte angeboten werden?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, ich finde das wirklich toll! So haben alle mehr Auswahl, egal welche Ernährung sie bevorzugen.'),
      DialogLine(isPersonA: true, text: 'Genau, und es ist auch besser für die Umwelt und die Gesundheit.'),
      DialogLine(isPersonA: false, text: 'Das stimmt. Außerdem probiere ich jetzt öfter mal neue Gerichte aus, die ich vorher nicht kannte.'),
      DialogLine(isPersonA: true, text: 'Mir gefällt auch, dass die Gerichte frisch zubereitet werden und nicht nur Fertiggerichte sind.'),
      DialogLine(isPersonA: false, text: 'Ja, das macht das Mittagessen in der Kantine viel angenehmer.'),
      DialogLine(isPersonA: true, text: 'Ich hoffe, dass das Angebot weiterhin so vielfältig bleibt.'),
      DialogLine(isPersonA: false, text: 'Ich auch! Vielleicht kommen ja noch mehr leckere Rezepte dazu.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ich finde es klasse, dass die Kantine auf verschiedene Ernährungsweisen Rücksicht nimmt.',
          'Mehr vegane und vegetarische Optionen sind ein guter Schritt.',
          'Das macht das Essen abwechslungsreicher und gesünder.',
          'Ich esse selbst öfter vegetarisch, und das Angebot ist wirklich gut.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Ich finde es gut, aber ich esse meistens trotzdem Fleisch.',
          'Manche Gerichte sind okay, andere mag ich nicht so.',
          'Es ist schön, dass es mehr Auswahl gibt, auch wenn ich nicht alles probiere.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik',
        phrases: [
          'Ich vermisse manchmal die traditionellen Gerichte.',
          'Manche vegane Gerichte schmecken mir nicht so.',
          'Ich hoffe, dass die Preise nicht zu hoch sind.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st35',
    number: 35,
    stimulus: 'Spielst du ein Musikinstrument? Ich würde gerne eins lernen. Kennst du hier gute Lehrmöglichkeiten?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, ich spiele Gitarre. Es macht viel Spaß, und es gibt hier einige Musikschulen in der Nähe.'),
      DialogLine(isPersonA: true, text: 'Das klingt super! Weißt du, ob es auch Kurse für Anfänger gibt?'),
      DialogLine(isPersonA: false, text: 'Ja, die meisten Musikschulen bieten Anfängerkurse an, oft auch für Erwachsene. Manche bieten sogar Online-Unterricht an.'),
      DialogLine(isPersonA: true, text: 'Online-Unterricht wäre für mich ideal, weil ich flexibel lernen kann.'),
      DialogLine(isPersonA: false, text: 'Genau. Außerdem kannst du dir auch Tutorials auf YouTube anschauen, das ist eine gute Ergänzung.'),
      DialogLine(isPersonA: true, text: 'Danke für die Tipps! Ich denke, ich probiere es mal mit Gitarre.'),
      DialogLine(isPersonA: false, text: 'Super! Wenn du möchtest, kann ich dir ein paar Noten und Lieder zeigen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung und Vorschläge',
        phrases: [
          'Ich finde es toll, ein Instrument zu lernen, es macht viel Freude.',
          'Viele Musikschulen bieten Kurse für verschiedene Instrumente an.',
          'Es gibt auch kostenlose Online-Kurse, die man ausprobieren kann.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Ich spiele kein Instrument, aber ich kenne Leute, die es gelernt haben.',
          'Man braucht viel Geduld und Übung.',
          'Man sollte ein Instrument wählen, das einem wirklich Spaß macht.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik oder Bedenken',
        phrases: [
          'Ein Instrument zu lernen ist zeitaufwendig.',
          'Manchmal ist es schwierig, regelmäßig zu üben.',
          'Man braucht oft auch eine gute Ausstattung.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st36',
    number: 36,
    stimulus: 'Diesen Sommer fahren wir im Urlaub nicht in die Heimat, sondern bleiben hier. Wollen wir mal etwas zusammen unternehmen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Das klingt nach einer tollen Idee! Es gibt bestimmt viele schöne Sachen, die man hier machen kann.'),
      DialogLine(isPersonA: true, text: 'Ja, vielleicht einen Ausflug an den See oder eine Fahrradtour.'),
      DialogLine(isPersonA: false, text: 'Oder wir könnten zusammen ein Picknick im Park machen.'),
      DialogLine(isPersonA: true, text: 'Genau, das wäre schön. Und vielleicht können wir auch abends zusammen grillen.'),
      DialogLine(isPersonA: false, text: 'Ich finde es super, die Zeit gemeinsam zu verbringen, auch wenn man nicht wegfährt.'),
      DialogLine(isPersonA: true, text: 'Dann lass uns bald einen Termin ausmachen!'),
      DialogLine(isPersonA: false, text: 'Ja, ich freue mich schon darauf.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ja, ich finde es toll, die Freizeit gemeinsam zu gestalten.',
          'Es gibt so viele Möglichkeiten für Ausflüge hier.',
          'Ich bin auf jeden Fall dabei!',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Mal schauen, wie das Wetter wird.',
          'Ich habe noch nicht so viele Pläne, aber ich melde mich.',
          'Vielleicht klappt es, wenn nichts dazwischenkommt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Ablehnung',
        phrases: [
          'Danke, aber ich habe schon andere Pläne.',
          'Ich möchte lieber zu Hause bleiben und entspannen.',
          'Ich bin nicht so der Ausflugsfan.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st37',
    number: 37,
    stimulus: 'Die Firma plant, ab diesem Jahr nur noch ein Sommerfest zu veranstalten. Die Weihnachtsfeier wird gestrichen. Wie findest du das?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hmm, das ist schade. Die Weihnachtsfeier war immer ein schöner Abschluss des Jahres.'),
      DialogLine(isPersonA: true, text: 'Ja, ich habe mich immer darauf gefreut. Das Sommerfest ist zwar auch nett, aber für mich ersetzt es die Weihnachtsfeier nicht.'),
      DialogLine(isPersonA: false, text: 'Vielleicht hat die Firma finanzielle Gründe. Oder sie wollen es einfacher machen.'),
      DialogLine(isPersonA: true, text: 'Das kann sein, aber ich finde, solche Feste sind wichtig für den Teamzusammenhalt.'),
      DialogLine(isPersonA: false, text: 'Da hast du recht. Ohne die Weihnachtsfeier fühlt sich das Jahr irgendwie unvollständig an.'),
      DialogLine(isPersonA: true, text: 'Vielleicht könnten wir als Team trotzdem etwas Kleines organisieren?'),
      DialogLine(isPersonA: false, text: 'Das wäre eine gute Idee. So bleibt die Tradition wenigstens ein bisschen erhalten.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ich finde es schade, aber das Sommerfest ist auch wichtig.',
          'Wichtig ist, dass man sich trifft und Zeit miteinander verbringt.',
          'Vielleicht ist es besser, sich auf ein großes Fest zu konzentrieren.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Es hat Vor- und Nachteile.',
          'Manche finden das Sommerfest besser, andere vermissen die Weihnachtsfeier.',
          'Die Firma will wahrscheinlich Kosten sparen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik',
        phrases: [
          'Ich finde es nicht gut, dass die Weihnachtsfeier gestrichen wird.',
          'Das zerstört die Tradition und den Teamgeist.',
          'Vielleicht fühlt sich das Team dadurch weniger wertgeschätzt.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st38',
    number: 38,
    stimulus: 'Weißt du, wie das in der Firma eigentlich mit der Krankmeldung geregelt ist?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, normalerweise muss man sich am ersten Krankheitstag beim Vorgesetzten oder der Personalabteilung melden.'),
      DialogLine(isPersonA: true, text: 'Okay, und wie lange habe ich Zeit, die Arbeitsunfähigkeitsbescheinigung vorzulegen?'),
      DialogLine(isPersonA: false, text: 'In vielen Firmen muss die Krankmeldung spätestens am dritten Tag eingereicht werden. Manche Unternehmen verlangen sie sogar schon am ersten Tag.'),
      DialogLine(isPersonA: true, text: 'Das wusste ich nicht. Gibt es Unterschiede, je nach Firma?'),
      DialogLine(isPersonA: false, text: 'Ja, das kann variieren. Am besten schaust du in den Arbeitsvertrag oder die Betriebsvereinbarung.'),
      DialogLine(isPersonA: true, text: 'Und was passiert, wenn man die Krankmeldung zu spät abgibt?'),
      DialogLine(isPersonA: false, text: 'Dann kann es sein, dass die Lohnfortzahlung verweigert wird oder es andere Konsequenzen gibt.'),
      DialogLine(isPersonA: true, text: 'Gut zu wissen. Danke für die Infos!'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung und Ergänzung',
        phrases: [
          'Ja, es ist wichtig, sich frühzeitig zu melden.',
          'Man sollte die Regeln genau kennen, um Probleme zu vermeiden.',
          'In unserer Firma muss die Krankmeldung meistens am zweiten Tag vorliegen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Ich bin mir nicht sicher, ich frage das bei der Personalabteilung nach.',
          'Es gibt unterschiedliche Regelungen, je nach Firma und Branche.',
          'Manchmal hängt es auch vom Arzt ab, wann die Bescheinigung ausgestellt wird.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik / Sorgen',
        phrases: [
          'Manche Firmen sind da sehr streng.',
          'Es ist manchmal schwer, alles rechtzeitig zu organisieren.',
          'Ich finde, die Regeln könnten flexibler sein.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st39',
    number: 39,
    stimulus: 'Hast du von dem Zuschuss der Firma für den Kauf eines E-Bikes gehört? Was denkst du darüber?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das habe ich! Ich finde das eine tolle Idee. So werden umweltfreundliche Verkehrsmittel gefördert.'),
      DialogLine(isPersonA: true, text: 'Genau, und es motiviert die Mitarbeiter, öfter mit dem Fahrrad zur Arbeit zu fahren.'),
      DialogLine(isPersonA: false, text: 'Außerdem ist das gut für die Gesundheit und reduziert den Stress durch den Verkehr.'),
      DialogLine(isPersonA: true, text: 'Ich überlege auch, ein E-Bike zu kaufen, wenn die Firma einen Zuschuss gibt.'),
      DialogLine(isPersonA: false, text: 'Das solltest du machen! Viele Firmen unterstützen das inzwischen, weil es auch die Mitarbeiterzufriedenheit steigert.'),
      DialogLine(isPersonA: true, text: 'Weißt du, wie man den Zuschuss beantragen kann?'),
      DialogLine(isPersonA: false, text: 'Ich denke, man muss sich an die Personalabteilung wenden und einen Antrag stellen. Oft gibt es dafür ein Formular.'),
      DialogLine(isPersonA: true, text: 'Danke für die Infos! Ich werde mich erkundigen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ich finde das eine sehr gute Maßnahme.',
          'Das fördert nachhaltige Mobilität.',
          'Es ist gut für die Umwelt und die Gesundheit.',
          'So ein Zuschuss motiviert wirklich.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Ich habe davon gehört, aber ich weiß nicht genau, wie das funktioniert.',
          'Es hängt davon ab, wie viel der Zuschuss beträgt.',
          'Nicht jeder braucht oder möchte ein E-Bike.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik',
        phrases: [
          'Manche finden das vielleicht nicht fair, wenn nicht alle profitieren.',
          'Ich bin mir nicht sicher, ob die Firma das lange durchhält.',
          'Ein Zuschuss ist gut, aber es gibt auch andere wichtige Themen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st40',
    number: 40,
    stimulus: 'Verbringst du wichtige Feiertage eher mit der Familie oder mit Freunden?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Meistens mit der Familie. Für mich sind die Feiertage eine Zeit, um mit meinen Angehörigen zusammen zu sein.'),
      DialogLine(isPersonA: true, text: 'Das kann ich gut verstehen. Bei mir ist es meistens auch so, obwohl ich manchmal auch Freunde treffe.'),
      DialogLine(isPersonA: false, text: 'Ja, Freunde sind natürlich auch wichtig, aber die Familie hat für mich Priorität an solchen Tagen.'),
      DialogLine(isPersonA: true, text: 'Manche Feiertage feiere ich auch mit Freunden, besonders wenn meine Familie weit weg wohnt.'),
      DialogLine(isPersonA: false, text: 'Das ist eine gute Lösung. Wichtig ist, dass man die Zeit mit Menschen verbringt, die einem wichtig sind.'),
      DialogLine(isPersonA: true, text: 'Genau, und es macht die Feiertage besonders schön.'),
      DialogLine(isPersonA: false, text: 'Stimmt! Wie ist es bei dir? Hast du einen Lieblingsfeiertag?'),
      DialogLine(isPersonA: true, text: 'Ja, ich mag Weihnachten sehr, weil die ganze Familie zusammenkommt.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Familienorientiert',
        phrases: [
          'Für mich sind die Feiertage eine Gelegenheit, Zeit mit der Familie zu verbringen.',
          'Familie hat an solchen Tagen einen besonderen Stellenwert.',
          'Ich finde es wichtig, Traditionen mit der Familie zu pflegen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Manchmal bin ich bei der Familie, manchmal bei Freunden.',
          'Es kommt auf den Feiertag und die Situation an.',
          'Ich genieße die Zeit einfach mit den Menschen, die mir wichtig sind.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Freunde bevorzugend',
        phrases: [
          'Ich verbringe die Feiertage meistens mit Freunden.',
          'Meine Familie wohnt weit weg, deshalb treffe ich mich mit Freunden.',
          'Freunde sind wie Familie, das ist mir wichtig.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st41',
    number: 41,
    stimulus: 'Was hältst du von Fahrgemeinschaften auf dem Weg zur Arbeit? Auf diese Weise könnte man Fahrtkosten sparen.',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich finde das eine gute Idee! Man spart nicht nur Geld, sondern es ist auch besser für die Umwelt.'),
      DialogLine(isPersonA: true, text: 'Genau, weniger Autos auf der Straße bedeuten weniger Verkehr und weniger CO₂-Ausstoß.'),
      DialogLine(isPersonA: false, text: 'Außerdem kann man sich während der Fahrt unterhalten, das macht den Weg zur Arbeit angenehmer.'),
      DialogLine(isPersonA: true, text: 'Das stimmt. Hast du schon mal in einer Fahrgemeinschaft mitgefahren?'),
      DialogLine(isPersonA: false, text: 'Ja, früher habe ich das oft gemacht. Es war praktisch und man konnte sich gut organisieren.'),
      DialogLine(isPersonA: true, text: 'Das klingt super. Ich denke, ich werde mal versuchen, eine Fahrgemeinschaft zu finden.'),
      DialogLine(isPersonA: false, text: 'Das ist eine gute Idee. Vielleicht gibt es in der Firma sogar eine Liste oder eine App dafür.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zustimmung',
        phrases: [
          'Ich finde Fahrgemeinschaften sehr sinnvoll.',
          'Das spart Geld und schont die Umwelt.',
          'Es ist auch eine gute Möglichkeit, Kollegen besser kennenzulernen.',
          'Man kann die Fahrtzeit nutzen, um sich auszutauschen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Neutral',
        phrases: [
          'Es hängt davon ab, ob man jemanden mit ähnlichem Arbeitsweg findet.',
          'Manchmal ist es nicht so flexibel, wenn die Zeiten unterschiedlich sind.',
          'Ich muss erst ausprobieren, ob das für mich passt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritik',
        phrases: [
          'Manche mögen es nicht, mit anderen zu fahren.',
          'Es ist weniger bequem als allein mit dem eigenen Auto.',
          'Man ist nicht so flexibel bei spontanen Änderungen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st42',
    number: 42,
    stimulus: 'Hallo! Sag mal, wie zahlst du eigentlich lieber – mit Bargeld oder lieber bargeldlos?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hallo! Also, ich zahle meistens mit Karte oder per Handy. Das ist einfach schneller und praktischer.'),
      DialogLine(isPersonA: true, text: 'Ja, stimmt. Ich nutze auch oft bargeldlose Zahlung, vor allem beim Einkaufen im Supermarkt.'),
      DialogLine(isPersonA: false, text: 'Und man muss kein Kleingeld suchen oder ständig schauen, ob man genug dabei hat.'),
      DialogLine(isPersonA: true, text: 'Aber manchmal finde ich Bargeld auch sinnvoll – zum Beispiel auf dem Wochenmarkt oder im Café.'),
      DialogLine(isPersonA: false, text: 'Stimmt, nicht überall kann man mit Karte zahlen. Ein bisschen Bargeld in der Tasche zu haben, ist nie schlecht.'),
      DialogLine(isPersonA: true, text: 'Genau! Vielleicht ist die Mischung aus beidem die beste Lösung.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Wenn bargeldlos bevorzugt',
        phrases: [
          'Ich finde bargeldlose Zahlungen viel moderner und hygienischer.',
          'Es ist auch praktisch, wenn man online etwas kaufen möchte.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Wenn bar bevorzugt',
        phrases: [
          'Ich fühle mich mit Bargeld sicherer, besonders bei kleinen Beträgen.',
          'So kann ich mein Budget besser kontrollieren.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Vorschlag',
        phrases: [
          'Vielleicht sollte man einfach beide Zahlungsmethoden nutzen – je nach Situation.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st43',
    number: 43,
    stimulus: 'Denkst du, es ist eine gute Idee, sich selbstständig zu machen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hm, das kommt darauf an. Ich finde, es ist eine tolle Chance, eigene Ideen umzusetzen.'),
      DialogLine(isPersonA: true, text: 'Stimmt, man kann selbst entscheiden, wie man arbeitet, und ist viel flexibler.'),
      DialogLine(isPersonA: false, text: 'Ja, aber es gibt auch Risiken. Man trägt die ganze Verantwortung selbst und das Einkommen ist nicht immer sicher.'),
      DialogLine(isPersonA: true, text: 'Das stimmt. Es kann auch sehr stressig sein, besonders am Anfang.'),
      DialogLine(isPersonA: false, text: 'Trotzdem finde ich, wenn man gut vorbereitet ist, kann es eine lohnende Entscheidung sein.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Pro Selbstständigkeit',
        phrases: [
          'Ich finde, man kann sich so besser verwirklichen und kreativ arbeiten.',
          'Außerdem gibt es oft keine festen Arbeitszeiten, das ist für viele ein Vorteil.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritisch',
        phrases: [
          'Es ist nicht einfach, Kunden zu finden und genug zu verdienen.',
          'Man muss sich gut mit Finanzen und Organisation auskennen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Vorschlag',
        phrases: [
          'Vielleicht könnte man zuerst nebenbei selbstständig arbeiten, um es auszuprobieren.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st44',
    number: 44,
    stimulus: 'Hast du auch mitbekommen, unsere Kantine wird für zwei Monate geschlossen, weil sie umgebaut wird? Was sagst du dazu?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das habe ich gehört. Ich finde es einerseits gut, dass sie modernisiert wird.'),
      DialogLine(isPersonA: true, text: 'Das stimmt, vielleicht wird das Essen danach besser oder das Angebot vielfältiger.'),
      DialogLine(isPersonA: false, text: 'Aber zwei Monate sind schon lang. Jetzt müssen wir jeden Tag selbst etwas mitbringen oder auswärts essen gehen.'),
      DialogLine(isPersonA: true, text: 'Ja, das wird wahrscheinlich teurer und unpraktischer für viele Mitarbeitende.'),
      DialogLine(isPersonA: false, text: 'Vielleicht könnte die Firma in der Zwischenzeit Essensgutscheine anbieten?'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Positiv',
        phrases: [
          'Endlich wird die Kantine renoviert, das war wirklich nötig.',
          'Ich hoffe, danach gibt es mehr vegetarische und gesunde Optionen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Kritisch',
        phrases: [
          'Für viele ist die Kantine eine wichtige Möglichkeit, günstig zu essen.',
          'In der Pause noch woanders hingehen zu müssen, ist echt stressig.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Vorschlag',
        phrases: [
          'Vielleicht könnte man für die Zeit einen Foodtruck oder mobile Essensangebote organisieren.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st45',
    number: 45,
    stimulus: 'Meinst du, dass man wirklich alle zwei Jahre ein neues Handy benötigt?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich finde, das ist nicht unbedingt nötig. Die meisten Handys funktionieren doch viel länger.'),
      DialogLine(isPersonA: true, text: 'Sehe ich auch so. Viele kaufen sich aber trotzdem immer das neueste Modell.'),
      DialogLine(isPersonA: false, text: 'Ja, das ist oft nur wegen der Werbung oder weil es ein Statussymbol ist.'),
      DialogLine(isPersonA: true, text: 'Und dabei ist es auch nicht gut für die Umwelt, ständig neue Geräte zu kaufen.'),
      DialogLine(isPersonA: false, text: 'Stimmt. Vielleicht sollte man lieber Reparaturen fördern und Geräte länger nutzen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Wenn jemand zustimmt',
        phrases: [
          'Neue Handys haben oft bessere Kameras und mehr Funktionen.',
          'In zwei Jahren wird die Technik oft wirklich deutlich besser.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Wenn jemand dagegen ist',
        phrases: [
          'Das ist Verschwendung – mein Handy funktioniert seit fünf Jahren problemlos.',
          'Man sollte Geräte nutzen, solange sie funktionieren.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Vorschlag',
        phrases: [
          'Vielleicht könnte man ein Programm einführen, um alte Handys zu recyceln oder weiterzugeben.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st46',
    number: 46,
    stimulus: 'Nächsten Monat muss ich in eine Wohnung umziehen. Könntest du mir mit der Renovierung der Wohnung helfen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Klar, ich helfe dir gerne! Wann genau willst du anfangen?'),
      DialogLine(isPersonA: true, text: 'Ich plane, am ersten Wochenende des Monats loszulegen. Da müsste gestrichen und ein bisschen repariert werden.'),
      DialogLine(isPersonA: false, text: 'Kein Problem, ich bringe sogar meine Werkzeuge mit.'),
      DialogLine(isPersonA: true, text: 'Super, das wäre wirklich eine große Hilfe. Ich lade dich danach auch zum Essen ein.'),
      DialogLine(isPersonA: false, text: 'Das klingt gut! Dann machen wir das zusammen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Wenn jemand helfen möchte',
        phrases: [
          'Natürlich, sag mir einfach, wann und was genau zu tun ist.',
          'Ich helfe dir gerne, ich habe sogar Erfahrung mit Streichen und Tapezieren.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Wenn jemand nicht helfen kann',
        phrases: [
          'Tut mir leid, ich bin in der Zeit schon verplant.',
          'Ich würde dir gern helfen, aber ich bin leider nicht handwerklich begabt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Vorschlag',
        phrases: [
          'Vielleicht könnten wir noch jemanden aus dem Freundeskreis fragen, der auch helfen kann.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st47',
    number: 47,
    stimulus: 'Findest du eine Betriebsfeier mit oder ohne Partner besser?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich finde es besser ohne Partner, dann kann man sich lockerer mit den Kolleginnen und Kollegen unterhalten. Und die Atmosphäre bleibt beruflich.'),
      DialogLine(isPersonA: true, text: 'Hm, ich sehe das ein bisschen anders. Mit Partner ist es doch auch schön – dann lernen die anderen auch den privaten Teil unseres Lebens kennen.'),
      DialogLine(isPersonA: false, text: 'Ja, das stimmt. Aber manche fühlen sich unwohl, wenn Partner dabei sind, besonders wenn sie niemanden mitbringen können.'),
      DialogLine(isPersonA: true, text: 'Vielleicht sollte man einfach beide Varianten mal ausprobieren.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Pro mit Partner',
        phrases: [
          'Ich finde es gut, wenn man den Partner mitbringen darf. So fühlt man sich entspannter.',
          'Es ist schön, wenn die Familie ein bisschen in das Arbeitsleben eingebunden wird.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Pro ohne Partner',
        phrases: [
          'Ohne Partner ist es einfacher, sich auf Gespräche mit Kollegen zu konzentrieren.',
          'Es bleibt professioneller und die Stimmung ist lockerer untereinander.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Vorschlag',
        phrases: [
          'Vielleicht könnte die Firma jedes zweite Jahr eine Feier mit Partner und eine ohne Partner organisieren.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st48',
    number: 48,
    stimulus: 'Ich mache gerne Überstunden. Du auch?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Manchmal schon, vor allem wenn viel zu tun ist. Aber ich versuche, nicht jeden Tag länger zu bleiben.'),
      DialogLine(isPersonA: true, text: 'Ja, ich finde es auch gut, wenn man die Arbeit schneller erledigen kann. Außerdem bekommt man oft mehr Geld dafür.'),
      DialogLine(isPersonA: false, text: 'Das stimmt, der finanzielle Aspekt ist für viele wichtig. Aber ich achte auch darauf, genug Freizeit zu haben, um mich zu erholen.'),
      DialogLine(isPersonA: true, text: 'Ja, Erholung ist wichtig. Trotzdem gibt es manchmal Phasen, in denen Überstunden unvermeidlich sind.'),
      DialogLine(isPersonA: false, text: 'Genau, gerade wenn Projekte anstehen oder Termine knapp sind, muss man manchmal flexibel sein.'),
      DialogLine(isPersonA: true, text: 'Wie gehst du dann mit Stress um, wenn es viele Überstunden gibt?'),
      DialogLine(isPersonA: false, text: 'Ich versuche, nach der Arbeit Sport zu machen oder mich mit Freunden zu treffen, um den Kopf frei zu bekommen. Und du?'),
      DialogLine(isPersonA: true, text: 'Ich mache gerne Spaziergänge oder höre Musik, das hilft mir sehr beim Abschalten.'),
      DialogLine(isPersonA: false, text: 'Das klingt gut! Ich denke, eine gute Balance zwischen Arbeit und Freizeit ist das Wichtigste.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative zu Satz 2',
        phrases: [
          'Eigentlich versuche ich, Überstunden zu vermeiden, aber manchmal geht es nicht anders.',
          'Ich mache lieber meine Arbeit während der normalen Arbeitszeit fertig.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Alternative zu Satz 4',
        phrases: [
          'Für mich ist Freizeit genauso wichtig wie das Gehalt.',
          'Ich finde, ohne Pause geht es auf Dauer nicht gut.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Alternative zu Satz 6',
        phrases: [
          'Stress versuche ich zu reduzieren, indem ich Pausen mache und bewusst abschalte.',
          'Wenn es zu viel wird, spreche ich mit meinem Chef, um Lösungen zu finden.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Alternative zu Satz 8',
        phrases: [
          'Musik hören hilft mir auch, um abzuschalten.',
          'Manchmal meditiere ich oder mache Yoga, das entspannt mich.',
        ],
      ),
    ],
  ),

  SmalltalkExercise(
    id: 'st49',
    number: 49,
    stimulus: 'Hast du gehört, dass es in der Firma bald kostenlose Sportkurse geben soll? Ich würde gerne dran teilnehmen. Und du?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das habe ich auch gehört. Ich finde das eine tolle Idee, um fit zu bleiben und den Stress abzubauen.'),
      DialogLine(isPersonA: true, text: 'Genau, ich denke, das ist auch gut für den Teamgeist. Gemeinsam macht Sport bestimmt mehr Spaß.'),
      DialogLine(isPersonA: false, text: 'Das sehe ich genauso. Vielleicht können wir ja zusammen mitmachen.'),
      DialogLine(isPersonA: true, text: 'Super, dann können wir uns gegenseitig motivieren.'),
      DialogLine(isPersonA: false, text: 'Ja, das hilft sicher, dranzubleiben und regelmäßig zu trainieren.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Antworten für Person B',
        phrases: [
          'Ehrlich gesagt, ich bin mir noch nicht sicher, ob ich mitmache. Sport ist nicht so mein Ding.',
          'Ich finde die Idee gut, aber ich habe leider nicht immer Zeit dafür.',
          'Für mich sind solche Angebote super, weil ich sonst selten Sport treibe.',
          'Ich freue mich darauf, das wird bestimmt gut für die Gesundheit sein.',
          'Ich mache schon regelmäßig Sport, aber die Kurse nehme ich trotzdem gern mit.',
        ],
      ),
    ],
  ),

  SmalltalkExercise(
    id: 'st50',
    number: 50,
    stimulus: 'Für mich wäre Schichtarbeit kein Problem. Wie siehst du das?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich finde Schichtarbeit manchmal schwierig, vor allem wegen des wechselnden Schlafrhythmus.'),
      DialogLine(isPersonA: true, text: 'Ja, das kann ich verstehen. Aber ich denke, man gewöhnt sich daran, wenn man den Alltag gut organisiert.'),
      DialogLine(isPersonA: false, text: 'Das stimmt, gute Planung ist wichtig. Trotzdem bevorzuge ich feste Arbeitszeiten.'),
      DialogLine(isPersonA: true, text: 'Das hat auch Vorteile, aber Schichtarbeit kann flexibler sein und manchmal sogar mehr Geld bringen.'),
      DialogLine(isPersonA: false, text: 'Ja, das stimmt. Aber für mich ist der geregelte Tagesablauf wichtiger.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Antworten für Person B',
        phrases: [
          'Schichtarbeit könnte ich mir auch gut vorstellen, ich mag Abwechslung. Für mich wäre Schichtarbeit eher ungeeignet, ich brauche einen festen Rhythmus. Ich denke, es kommt darauf an, wie gut man sich anpasst. Ich habe gehört, dass Schichtarbeit gesundheitlich belastend sein kann. Manchmal macht Schichtarbeit Sinn, aber auf Dauer bevorzuge ich feste Zeiten.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st51',
    number: 51,
    stimulus: 'Wollen wir mal an einem Abend etwas mit Kolleg*innen unternehmen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das klingt super! Hast du schon eine Idee, was wir machen könnten?'),
      DialogLine(isPersonA: true, text: 'Ich habe an ein gemeinsames Abendessen gedacht, vielleicht in einem netten Restaurant in der Stadt.'),
      DialogLine(isPersonA: false, text: 'Gute Idee. Wir könnten auch überlegen, ob wir danach noch etwas anderes machen, zum Beispiel ins Kino gehen.'),
      DialogLine(isPersonA: true, text: 'Stimmt, oder wir könnten Bowling spielen. Das macht meistens allen Spaß.'),
      DialogLine(isPersonA: false, text: 'Ja, Bowling wäre lustig. Ich glaube, viele aus unserem Team haben das schon lange nicht mehr gemacht.'),
      DialogLine(isPersonA: true, text: 'Ich frage einfach mal in der Abteilung, wer Lust hat und was die meisten bevorzugen.'),
      DialogLine(isPersonA: false, text: 'Ja, das ist gut. Vielleicht können wir auch eine kleine Umfrage per E-Mail machen.'),
      DialogLine(isPersonA: true, text: 'Genau, so können wir auch gleich ein Datum finden, das allen passt.'),
      DialogLine(isPersonA: false, text: 'Und vielleicht könnten wir vorher einen kleinen Spaziergang machen, wenn das Wetter schön ist.'),
      DialogLine(isPersonA: true, text: 'Das klingt entspannt. Wir könnten uns direkt nach der Arbeit treffen, damit es nicht zu spät wird.'),
      DialogLine(isPersonA: false, text: 'Ja, dann haben wir noch genug Zeit für alles. Ich freue mich schon darauf!'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zu Satz 2 („Ja, das klingt super!“)',
        phrases: [
          'Ja, sehr gern! Wir haben schon lange nichts gemeinsam unternommen. Klingt gut! Das wäre eine tolle Abwechslung nach der Arbeit. Ja, das wäre schön, dann sehen wir uns mal außerhalb des Büros.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Zu Satz 4 („Gute Idee.“)',
        phrases: [
          'Oh ja, Kino wäre auch klasse, da könnten wir uns einen neuen Film anschauen. Ja, oder vielleicht könnten wir einen Spieleabend organisieren. Stimmt, es gibt viele Möglichkeiten.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Zu Satz 6 („Ja, Bowling wäre lustig.“)',
        phrases: [
          'Ja, Bowling ist super – da kann jeder mitmachen, egal ob er gut spielt oder nicht. Genau, und man kann dabei auch gut miteinander reden. Ja, das ist etwas, das fast allen Spaß macht.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Zu Satz 8 („Ja, das ist gut.“)',
        phrases: [
          'Ja, so wissen wir gleich, wer Interesse hat. Stimmt, dann ist es einfacher zu planen. Ja, und wir können auch gleich sehen, welcher Termin am besten passt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Zu Satz 10 („Und vielleicht könnten wir vorher einen kleinen Spaziergang machen“)',
        phrases: [
          'Ja, das wäre eine gute Idee, besonders wenn das Wetter schön ist. Stimmt, frische Luft tut gut vor dem Essen. Ja, das würde den Abend noch entspannter machen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Zu Satz 12 („Ja, dann haben wir noch genug Zeit für alles.“)',
        phrases: [
          'Genau, so wird es nicht zu spät. Stimmt, dann können auch die mitkommen, die früh ins Bett wollen. Ja, und wir haben trotzdem einen langen Abend zusammen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st52',
    number: 52,
    stimulus: 'Arbeitest du lieber im Team oder alleine?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich arbeite ehrlich gesagt lieber allein. So kann ich mich besser konzentrieren.'),
      DialogLine(isPersonA: true, text: 'Interessant, ich persönlich bevorzuge im Team zu arbeiten.'),
      DialogLine(isPersonA: false, text: 'Ja, Teamarbeit hat Vorteile, aber oft dauert es länger, bis alle sich einig sind.'),
      DialogLine(isPersonA: true, text: 'Stimmt, manchmal gibt es viele Diskussionen. Trotzdem finde ich, dass man im Team kreativere Lösungen findet.'),
      DialogLine(isPersonA: false, text: 'Das mag sein, aber ich habe die Erfahrung gemacht, dass ich alleine schneller fertig bin.'),
      DialogLine(isPersonA: true, text: 'Ja, das kann ich nachvollziehen. Aber im Team kann man sich gegenseitig helfen.'),
      DialogLine(isPersonA: false, text: 'Das stimmt. Am besten ist wahrscheinlich eine Mischung aus beidem.'),
      DialogLine(isPersonA: true, text: 'Ja, da sind wir uns einig.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Zu Satz 2 („Ich arbeite lieber allein“)',
        phrases: [
          'Ich mag beides, aber allein bin ich oft produktiver. Lieber im Team, aber nur, wenn es gut organisiert ist. Eigentlich mag ich Teamarbeit nicht so sehr, wegen der vielen Besprechungen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Zu Satz 4 („Teamarbeit hat Vorteile, aber…“)',
        phrases: [
          'Teamarbeit kann Spaß machen, aber manchmal ist sie anstrengend. Ich finde, allein ist es ruhiger und weniger stressig. Im Team ist oft viel Small Talk, und das lenkt mich ab.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Zu Satz 6 („Ich alleine schneller fertig bin“)',
        phrases: [
          'Das stimmt nicht immer, manchmal brauche ich länger. Ja, aber manchmal fehlen mir dann neue Ideen. Ich finde, das hängt von der Aufgabe ab.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Zu Satz 8 („Am besten eine Mischung aus beidem“)',
        phrases: [
          'Für mich reicht Einzelarbeit völlig. Ich denke, Teams sind für große Projekte besser geeignet. Das kommt auf die Kollegen an.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st53',
    number: 53,
    stimulus: 'Unser Betriebsausflug findet am Samstag statt. Was hältst du davon?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hm, ehrlich gesagt finde ich das etwas ungünstig. Samstag ist für mich eigentlich Familienzeit.'),
      DialogLine(isPersonA: true, text: 'Ja, das verstehe ich. Ich finde es aber schön, mal etwas gemeinsam mit allen Kollegen zu unternehmen.'),
      DialogLine(isPersonA: false, text: 'Klar, das stimmt. Es stärkt bestimmt den Teamgeist.'),
      DialogLine(isPersonA: true, text: 'Außerdem ist es entspannter, wenn wir keinen Arbeitstag dafür opfern müssen.'),
      DialogLine(isPersonA: false, text: 'Ja, das ist ein Vorteil. Aber ich muss trotzdem schauen, wie ich das mit meinen privaten Terminen kombiniere.'),
      DialogLine(isPersonA: true, text: 'Vielleicht kannst du einfach etwas früher gehen, wenn es dir zu lange dauert.'),
      DialogLine(isPersonA: false, text: 'Das wäre eine Möglichkeit. Ich hoffe, das Programm ist interessant.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Alternative Antworten für Person B Antwort auf „Was hältst du davon?“',
        phrases: [
          'Ich finde es super, so können wir alle mal außerhalb der Arbeit reden. Mir ist der Samstag nicht so recht, ich hätte lieber einen Wochentag genommen. Eigentlich passt es mir gut, da habe ich meistens Zeit. Ich weiß noch nicht, ob ich mitkommen kann, ich habe schon andere Pläne.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Antwort auf „Es stärkt den Teamgeist.“',
        phrases: [
          'Ja, das stimmt, und man lernt die Kollegen besser kennen. Vielleicht, aber manchmal ist es auch anstrengend, so viel Zeit miteinander zu verbringen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Antwort auf „Es ist entspannter, keinen Arbeitstag zu opfern.“',
        phrases: [
          'Ja, stimmt, so verlieren wir keine Arbeitszeit. Für mich wäre ein freier Arbeitstag aber auch schön gewesen.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st54',
    number: 54,
    stimulus: 'Ich nehme an Brückentagen immer frei. Und du?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Meistens schon, aber nicht immer. Manchmal nutze ich die Tage lieber, um in Ruhe im Büro zu arbeiten.'),
      DialogLine(isPersonA: true, text: 'Ach, interessant. Ich finde es schön, ein langes Wochenende zu haben.'),
      DialogLine(isPersonA: false, text: 'Ja, das stimmt, das ist schon erholsam.'),
      DialogLine(isPersonA: true, text: 'Außerdem kann man in dieser Zeit auch kleine Ausflüge machen.'),
      DialogLine(isPersonA: false, text: 'Genau, das mache ich manchmal auch. Aber wenn viele Kollegen frei haben, ist es im Büro oft angenehm ruhig.'),
      DialogLine(isPersonA: true, text: 'Stimmt, das kann auch ein Vorteil sein.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Und du?“',
        phrases: [
          'Ja, ich nehme auch immer frei. Das ist wie ein kleines Geschenk. Nein, ich arbeite oft an Brückentagen. Dann ist es im Büro angenehm leer. Manchmal, es hängt davon ab, wie viele Urlaubstage ich noch habe. Selten, ich hebe mir meine Urlaubstage lieber für längere Reisen auf.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Ich finde es schön, ein langes Wochenende zu haben.“',
        phrases: [
          'Ja, das ist wirklich erholsam. Mag sein, aber ich langweile mich manchmal, wenn ich zu Hause bleibe.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Man kann kleine Ausflüge machen.“',
        phrases: [
          'Ja, stimmt, das ist eine gute Gelegenheit. Möglich, aber oft sind die Ausflugsziele dann sehr voll.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st55',
    number: 55,
    stimulus: 'Ich finde einen Tag extra Urlaub für einen Umzug sehr wenig. Was denkst du darüber?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das sehe ich auch so. Ein Umzug ist viel Arbeit, da braucht man eigentlich mehrere Tage.'),
      DialogLine(isPersonA: true, text: 'Genau, man muss packen, transportieren und wieder auspacken.'),
      DialogLine(isPersonA: false, text: 'Und oft muss man auch noch renovieren oder putzen.'),
      DialogLine(isPersonA: true, text: 'Eben, ein Tag reicht dafür nicht aus.'),
      DialogLine(isPersonA: false, text: 'Vielleicht könnte man es so regeln, dass man zwei oder drei Tage bekommt, je nach Entfernung.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Was denkst du darüber?“',
        phrases: [
          'Ich finde auch, dass ein Tag zu wenig ist. Ich sehe das anders, ein Tag ist genug, wenn man gut organisiert ist. Hängt davon ab, ob der Umzug in der gleichen Stadt ist oder weiter weg. Für mich war ein Tag immer ausreichend, aber ich verstehe, wenn es für andere zu wenig ist.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Ein Tag reicht dafür nicht.“',
        phrases: [
          'Ja, besonders wenn man Möbel aufbauen muss. Ich glaube, mit Hilfe von Freunden kann es klappen. Stimmt, und man hat ja oft noch Arbeit nebenbei.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st56',
    number: 56,
    stimulus: 'Alle Fortbildungen sollen dieses Jahr an Wochenenden stattfinden. Was hältst du davon?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ehrlich gesagt, ich finde das nicht ideal. Wochenenden sind für mich Erholungszeit.'),
      DialogLine(isPersonA: true, text: 'Ja, das verstehe ich. Ich persönlich finde es aber praktisch, weil man unter der Woche keine Arbeit dafür unterbrechen muss.'),
      DialogLine(isPersonA: false, text: 'Stimmt, das hat den Vorteil, dass der normale Arbeitsablauf nicht gestört wird.'),
      DialogLine(isPersonA: true, text: 'Genau. Aber ich fürchte, dass manche Mitarbeitenden müde sein könnten, weil sie arbeiten und dann auch noch am Wochenende Fortbildung haben.'),
      DialogLine(isPersonA: false, text: 'Ja, das könnte passieren. Außerdem hat man kaum Freizeit für Familie oder Freunde.'),
      DialogLine(isPersonA: true, text: 'Vielleicht könnte man es so organisieren, dass man die Fortbildungen auf halbe Tage verteilt oder die Wochenenden abwechselt.'),
      DialogLine(isPersonA: false, text: 'Das wäre eine gute Idee. So bleibt die Belastung überschaubar und jeder kann teilnehmen.'),
      DialogLine(isPersonA: true, text: 'Ich hoffe, die Firma berücksichtigt auch, dass manche schon feste Pläne für das Wochenende haben.'),
      DialogLine(isPersonA: false, text: 'Ja, das sollte unbedingt möglich sein. Freiwilligkeit oder Ausweichtermine wären fair.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Was hältst du davon?“',
        phrases: [
          'Ich finde es nicht optimal, weil ich am Wochenende gerne frei habe. Ich sehe das positiv, dann wird die Arbeitswoche nicht unterbrochen. Es kommt darauf an, ob es gut organisiert wird. Ich finde es okay, aber nur, wenn die Fortbildungen kurz sind.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Unter der Woche keine Arbeit unterbrechen“',
        phrases: [
          'Ja, das ist ein Vorteil, aber dafür opfert man Freizeit. Genau, so bleibt die Woche stressfrei. Stimmt, das spart Zeit im Job.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Belastung überschaubar halten“',
        phrases: [
          'Ja, Abwechslung und halbe Tage wären gut. Vielleicht kann man auch einzelne Module online anbieten.',
          'Freiwilligkeit wäre für mich wichtig, sonst ist die Motivation gering.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st57',
    number: 57,
    stimulus: 'Du arbeitest doch Vollzeit, oder? Wie schaffst du das denn mit deinem Kind?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, ich arbeite Vollzeit. Es ist manchmal schon eine Herausforderung, aber wir haben eine gute Betreuung organisiert.'),
      DialogLine(isPersonA: true, text: 'Ah, das ist wichtig. Gehst du früh zur Arbeit oder eher später?'),
      DialogLine(isPersonA: false, text: 'Ich beginne meistens um acht Uhr, und mein Kind geht vormittags in die Kita. Danach hole ich es am Nachmittag ab.'),
      DialogLine(isPersonA: true, text: 'Und was machst du, wenn es krank wird oder die Kita geschlossen ist?'),
      DialogLine(isPersonA: false, text: 'Dann muss mein Partner einspringen oder ich nehme einen Tag Homeoffice, wenn möglich. Es klappt nicht immer perfekt, aber wir versuchen, uns abzuwechseln.'),
      DialogLine(isPersonA: true, text: 'Das klingt nach guter Organisation. Hast du noch Zeit für dich selbst?'),
      DialogLine(isPersonA: false, text: 'Nicht so viel, wie ich gern hätte, aber abends oder am Wochenende finde ich kleine Momente für mich.'),
      DialogLine(isPersonA: true, text: 'Das kenne ich. Ich finde es bewundernswert, wie du das alles unter einen Hut bekommst.'),
      DialogLine(isPersonA: false, text: 'Danke. Es ist nicht immer leicht, aber mit Planung und Unterstützung geht es.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Wie schaffst du das denn?“',
        phrases: [
          'Es ist manchmal stressig, aber wir haben feste Routinen. Ich habe Glück, dass mein Partner mich unterstützt. Es ist nicht immer einfach, aber wir bekommen das hin. Manchmal muss ich Überstunden reduzieren oder flexibel arbeiten.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Was machst du, wenn das Kind krank ist?“',
        phrases: [
          'Dann nehme ich Homeoffice, wenn möglich. Mein Partner springt dann ein, oder wir organisieren eine Notbetreuung. Ich versuche, Aufgaben anders zu verteilen, damit alles klappt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Hast du noch Zeit für dich selbst?“',
        phrases: [
          'Nicht viel, aber kleine Pausen helfen. Ich versuche, abends oder am Wochenende auszuspannen. Meistens ist die Zeit knapp, aber die Familie geht vor.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st58',
    number: 58,
    stimulus: 'Dieses Jahr fällt unser Betriebsausflug aus. Was hältst du davon?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ehrlich gesagt, ich finde es schade. Ich habe mich schon auf den Ausflug gefreut.'),
      DialogLine(isPersonA: true, text: 'Ja, ich auch. Es wäre schön gewesen, mal außerhalb der Arbeit Zeit miteinander zu verbringen.'),
      DialogLine(isPersonA: false, text: 'Genau, so lernt man die Kolleginnen und Kollegen auch mal anders kennen.'),
      DialogLine(isPersonA: true, text: 'Aber vielleicht ist es auch verständlich, wenn die Firma gerade sparen muss oder die Organisation schwierig ist.'),
      DialogLine(isPersonA: false, text: 'Ja, das stimmt. In der aktuellen Lage ist es vielleicht wirklich die beste Entscheidung.'),
      DialogLine(isPersonA: true, text: 'Trotzdem hoffe ich, dass wir nächstes Jahr wieder einen Ausflug machen können.'),
      DialogLine(isPersonA: false, text: 'Ich auch. Vielleicht könnte man alternativ ein kleines Treffen oder ein gemeinsames Mittagessen organisieren.'),
      DialogLine(isPersonA: true, text: 'Ja, das wäre eine gute Idee, so bleibt der Teamgeist erhalten.'),
      DialogLine(isPersonA: false, text: 'Genau, und es zeigt, dass die Firma die Mitarbeitenden trotzdem wertschätzt.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Was hältst du davon?“',
        phrases: [
          'Ich finde es schade, aber ich verstehe die Gründe. Eigentlich ist es in Ordnung, vielleicht war es dieses Jahr einfach zu aufwendig. Ich finde es gar nicht schlimm, dann hat man mal ein ruhiges Wochenende. Schade, aber wir können ja etwas anderes gemeinsam machen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „So lernt man die Kollegen anders kennen“',
        phrases: [
          'Ja, genau, solche Aktivitäten verbinden das Team. Stimmt, aber manchmal ist es auch entspannter, wenn man keine großen Ausflüge plant.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Vielleicht könnte man alternativ…“',
        phrases: [
          'Ja, ein kleines Treffen wäre gut, dann bleibt der Kontakt. Stimmt, ein gemeinsames Mittagessen ist eine schöne Alternative. Oder man organisiert einen Online-Austausch, wenn persönliche Treffen schwierig sind.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st59',
    number: 59,
    stimulus: 'Was wäre eine gute Idee für unseren nächsten Betriebsausflug?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hm, vielleicht könnten wir etwas draußen machen, wie eine Wanderung oder einen Ausflug an einen See.'),
      DialogLine(isPersonA: true, text: 'Das klingt schön. So hätten wir frische Luft und Bewegung.'),
      DialogLine(isPersonA: false, text: 'Genau, das ist auch gut für den Teamgeist. Man unterhält sich mehr und lernt sich besser kennen.'),
      DialogLine(isPersonA: true, text: 'Wir könnten aber auch etwas Kreatives machen, wie einen Kochkurs oder einen Workshop.'),
      DialogLine(isPersonA: false, text: 'Ja, das wäre interessant. Manche Kolleginnen und Kollegen mögen das bestimmt sehr.'),
      DialogLine(isPersonA: true, text: 'Oder wir kombinieren beides: Vormittags etwas Aktivität draußen und nachmittags ein gemeinsames Essen oder Workshop.'),
      DialogLine(isPersonA: false, text: 'Das wäre ideal. Dann ist für jeden etwas dabei und es bleibt abwechslungsreich.'),
      DialogLine(isPersonA: true, text: 'Vielleicht könnten wir eine kleine Umfrage machen, damit jeder seine Meinung einbringen kann.'),
      DialogLine(isPersonA: false, text: 'Genau, so bekommen wir ein Programm, das allen Spaß macht.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Was wäre eine gute Idee?“',
        phrases: [
          'Ich würde etwas im Freien vorschlagen, wie Wandern oder Radfahren. Vielleicht ein Teamspiel oder eine kleine Challenge, das macht allen Spaß. Ein Workshop oder ein gemeinsames Kochen könnte spannend sein.',
          'Etwas Kreatives, bei dem alle mitmachen können, wäre auch schön.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Das ist gut für den Teamgeist“',
        phrases: [
          'Ja, genau, so kommt man leichter ins Gespräch. Stimmt, aber manche sind lieber allein aktiv. Das kann sein, aber ich finde, Teamaktivitäten verbinden mehr.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Eine Umfrage machen“',
        phrases: [
          'Ja, das wäre fair, so kann jeder seine Wünsche äußern. Stimmt, dann haben alle ein Mitspracherecht. Vielleicht machen wir eine kurze Abstimmung, dann ist es schnell entschieden.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st60',
    number: 60,
    stimulus: 'Bald ziehen wir um. Im neuen Gebäude arbeiten wir im Großraumbüro. Freust du dich auch darauf?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ehrlich gesagt bin ich ein bisschen unsicher. Großraumbüros sind ja oft laut, und konzentriertes Arbeiten kann schwierig sein.'),
      DialogLine(isPersonA: true, text: 'Ja, das stimmt. Ich bin gespannt, wie es wird. Ich hoffe, dass die Arbeitsplätze gut geplant sind und es trotzdem Rückzugsmöglichkeiten gibt.'),
      DialogLine(isPersonA: false, text: 'Genau, das wäre wichtig. Vielleicht gibt es ruhige Bereiche oder kleine Besprechungsräume.'),
      DialogLine(isPersonA: true, text: 'Ich denke, es hat auch Vorteile: Man kann schneller miteinander sprechen und Ideen austauschen.'),
      DialogLine(isPersonA: false, text: 'Ja, der Austausch ist sicher einfacher. Aber manchmal fehlt die Privatsphäre, und Telefonate können störend sein.'),
      DialogLine(isPersonA: true, text: 'Vielleicht könnten wir uns feste Zeiten für konzentriertes Arbeiten einrichten, damit alle profitieren.'),
      DialogLine(isPersonA: false, text: 'Das wäre eine gute Lösung. Ich freue mich trotzdem auf das neue Gebäude, besonders auf die modernen Einrichtungen.'),
      DialogLine(isPersonA: true, text: 'Stimmt, die Technik und die Räume sind sicher ein großer Vorteil. Dann wird sich das Großraumbüro vielleicht leichter akzeptieren lassen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Freust du dich auch darauf?“',
        phrases: [
          'Ich bin gespannt, aber auch ein bisschen skeptisch wegen der Lautstärke. Ja, ich freue mich, besonders auf die neuen Räume und Technik. Ich weiß noch nicht, ob mir das Großraumbüro gefallen wird. Für mich ist es okay, ich mag die offene Atmosphäre.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Vielleicht gibt es ruhige Bereiche…“',
        phrases: [
          'Ja, das wäre wirklich wichtig. Ich hoffe, dass die Firma daran gedacht hat. Wenn nicht, wird es schwierig mit konzentriertem Arbeiten.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Vorteile: Austausch und Ideen“',
        phrases: [
          'Ja, das stimmt, schnelle Kommunikation ist ein Plus. Das sehe ich auch, aber manchmal ist es zu laut.',
          'Ich finde, man verliert dabei ein bisschen Ruhe für komplexe Aufgaben.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Feste Zeiten für konzentriertes Arbeiten“',
        phrases: [
          'Ja, das wäre eine gute Lösung. Das könnte helfen, den Lärm zu minimieren. Ich hoffe, dass sich alle daran halten.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st61',
    number: 61,
    stimulus: 'Ich wünsche, es gäbe mehr vegetarische Gerichte in der Kantine. Was denkst du darüber?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, ich finde das auch eine gute Idee. Es gibt nur wenige Optionen, und manchmal bleibt einem gar nichts anderes übrig.'),
      DialogLine(isPersonA: true, text: 'Genau, und es wäre gesünder, wenn mehr Gemüsegerichte angeboten würden.'),
      DialogLine(isPersonA: false, text: 'Stimmt. Allerdings essen viele Kollegen lieber Fleisch, deswegen könnte die Auswahl schwerfallen.'),
      DialogLine(isPersonA: true, text: 'Vielleicht könnte man abwechselnd vegetarische und Fleischgerichte anbieten, damit für alle etwas dabei ist.'),
      DialogLine(isPersonA: false, text: 'Ja, das wäre fair. Außerdem würde es auch umweltfreundlicher sein, mehr vegetarische Optionen anzubieten.'),
      DialogLine(isPersonA: true, text: 'Genau, und für Vegetarier oder Leute mit Lebensmittelunverträglichkeiten wäre es eine Erleichterung.'),
      DialogLine(isPersonA: false, text: 'Ich hoffe, dass die Kantine darauf eingeht. Vielleicht könnten wir einen Vorschlag einreichen.'),
      DialogLine(isPersonA: true, text: 'Ja, das ist eine gute Idee. Dann hätten wir alle die Chance, das Essen abwechslungsreicher zu gestalten.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Was denkst du darüber?“',
        phrases: [
          'Ich finde das auch wichtig, es gibt wirklich zu wenige vegetarische Gerichte. Ehrlich gesagt esse ich lieber Fleisch, aber mehr Gemüse schadet sicher nicht. Ich sehe das neutral, Hauptsache, die Auswahl ist vielfältig. Mir ist es egal, solange die Gerichte schmecken.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Viele Kollegen essen lieber Fleisch“',
        phrases: [
          'Ja, das stimmt, aber man könnte trotzdem ein paar vegetarische Optionen anbieten. Stimmt, vielleicht sollten wir eine Umfrage machen, was die Mehrheit will. Ich glaube, die meisten würden die vegetarischen Gerichte trotzdem probieren.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st62',
    number: 62,
    stimulus: 'Ich finde es gut, wenn wir uns einmal im Monat abends zu einem Stammtisch treffen würden. Und du? Machst du mit?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das klingt eigentlich interessant. Ich finde, das stärkt den Zusammenhalt im Team.'),
      DialogLine(isPersonA: true, text: 'Genau, man kann sich auch über Dinge unterhalten, die nichts mit der Arbeit zu tun haben.'),
      DialogLine(isPersonA: false, text: 'Stimmt. Aber abends bin ich manchmal müde oder habe schon private Pläne.'),
      DialogLine(isPersonA: true, text: 'Ja, das verstehe ich. Vielleicht kann jeder selbst entscheiden, an welchen Terminen er teilnehmen möchte.'),
      DialogLine(isPersonA: false, text: 'Das wäre fair. Dann könnte ich auch gelegentlich dabei sein.'),
      DialogLine(isPersonA: true, text: 'Wir könnten auch kleine Themen oder Spiele vorbereiten, damit es lustig und locker bleibt.'),
      DialogLine(isPersonA: false, text: 'Gute Idee. So wird der Stammtisch interessant und alle haben Spaß.'),
      DialogLine(isPersonA: true, text: 'Super, dann machen wir am besten einen Vorschlag für das erste Treffen.'),
      DialogLine(isPersonA: false, text: 'Ja, ich bin dabei, wenn es passt. Dann sehen wir, wie es läuft.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Und du? Machst du mit?“',
        phrases: [
          'Ja, ich finde die Idee gut und würde gerne mitkommen. Manchmal, aber nicht immer. Ich habe abends manchmal andere Pläne. Ich weiß noch nicht, ob ich regelmäßig teilnehmen kann. Nein, abends ist mir meist zu spät, aber die Idee finde ich gut.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Das stärkt den Zusammenhalt“',
        phrases: [
          'Ja, genau, das macht das Team noch enger. Stimmt, aber manche sind eher zurückhaltend. Das kann sein, aber nicht jeder möchte abends teilnehmen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Vielleicht kann jeder selbst entscheiden…“',
        phrases: [
          'Ja, so ist es fair für alle. Genau, das würde mir entgegenkommen. Ich hoffe, dass viele mitmachen, auch wenn es freiwillig ist.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Dann sehen wir, wie es läuft“',
        phrases: [
          'Ja, das probieren wir einfach mal aus. Genau, dann kann man immer noch Anpassungen machen. Ich bin gespannt, wie es ankommt.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st63',
    number: 63,
    stimulus: 'Ich überlege, meine Stunden zu reduzieren und in Teilzeit zu arbeiten. Was denkst du? Ist das gut?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Hm, das kommt darauf an. Teilzeit kann gut sein, wenn man mehr Zeit für Familie oder Freizeit braucht.'),
      DialogLine(isPersonA: true, text: 'Genau, ich würde dann mehr Zeit für meine Kinder haben und etwas Stress abbauen.'),
      DialogLine(isPersonA: false, text: 'Das stimmt. Aber manchmal ist es schwierig, alle Aufgaben in weniger Stunden zu erledigen.'),
      DialogLine(isPersonA: true, text: 'Ja, das ist ein Nachteil, aber vielleicht kann man die Arbeit besser planen.'),
      DialogLine(isPersonA: false, text: 'Auch die Kollegen könnten es bemerken, wenn sie mehr Verantwortung übernehmen müssen.'),
      DialogLine(isPersonA: true, text: 'Das stimmt, aber ich hoffe, dass wir eine gute Lösung finden, die für alle passt.'),
      DialogLine(isPersonA: false, text: 'Ja, wenn die Arbeitsaufteilung fair ist, kann Teilzeit wirklich vorteilhaft sein.'),
      DialogLine(isPersonA: true, text: 'Genau, und ich denke, meine Motivation wird dadurch sogar steigen.'),
      DialogLine(isPersonA: false, text: 'Ich glaube auch, dass es für die Balance zwischen Arbeit und Privatleben sehr hilfreich sein kann.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Ist das gut?“',
        phrases: [
          'Ja, das kann gut sein, besonders wenn du mehr Zeit für Familie brauchst. Ich bin mir nicht sicher, manchmal kann es stressig sein, alles in weniger Stunden zu erledigen. Teilzeit ist gut, wenn man die Arbeit gut organisieren kann. Es kommt auf die Art der Arbeit und die Kollegen an.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Manchmal ist es schwierig, alle Aufgaben zu erledigen“',
        phrases: [
          'Ja, das ist ein Nachteil, aber Planung kann helfen. Stimmt, vielleicht muss man Aufgaben anders verteilen. Das hängt auch davon ab, wie das Team reagiert.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Kollegen könnten es bemerken“',
        phrases: [
          'Ja, die Arbeitslast muss fair verteilt werden. Das ist richtig, gute Kommunikation ist wichtig. Wenn alle zusammenarbeiten, ist es kein Problem.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Motivation steigt dadurch“',
        phrases: [
          'Ja, weniger Stress kann wirklich die Motivation erhöhen. Genau, so bleibt auch mehr Energie für die Arbeit. Stimmt, die Work-Life-Balance wird besser.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st64',
    number: 64,
    stimulus: 'Mein Zug kommt jeden Morgen spät. Ich habe Angst, ich bekomme bald Ärger vom Chef. Was soll ich machen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Oh, das ist ärgerlich. Vielleicht könntest du vorher kurz Bescheid sagen, wenn du wieder einmal zu spät kommst.'),
      DialogLine(isPersonA: true, text: 'Ja, das habe ich schon versucht, aber manchmal ist es so kurzfristig, dass ich es nicht vorher weiß.'),
      DialogLine(isPersonA: false, text: 'Dann könntest du vielleicht überlegen, früher loszufahren oder alternative Verbindungen zu nehmen.'),
      DialogLine(isPersonA: true, text: 'Das habe ich auch schon geprüft, aber es gibt nur wenige frühere Züge.'),
      DialogLine(isPersonA: false, text: 'Vielleicht kann man mit dem Chef reden und erklären, dass es an der Bahn liegt und nicht an deiner Unpünktlichkeit.'),
      DialogLine(isPersonA: true, text: 'Ja, das ist eine gute Idee. Ich will nur nicht, dass es so aussieht, als sei ich unzuverlässig.'),
      DialogLine(isPersonA: false, text: 'Genau. Ehrlichkeit ist wichtig. Manchmal akzeptiert der Chef auch flexible Lösungen, zum Beispiel Gleitzeit.'),
      DialogLine(isPersonA: true, text: 'Stimmt, vielleicht kann ich morgens ein bisschen später anfangen und dafür länger bleiben.'),
      DialogLine(isPersonA: false, text: 'Ja, das wäre eine faire Lösung für beide Seiten. Dann bleibt der Job stressfrei und der Chef zufrieden.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Was soll ich machen?“',
        phrases: [
          'Sprich offen mit deinem Chef, das zeigt, dass du die Situation ernst nimmst. Vielleicht kannst du morgens früher losfahren oder eine alternative Strecke nehmen. Wenn möglich, nutze Gleitzeit oder flexible Arbeitszeiten. Du könntest auch versuchen, den Zugfahrplan zu prüfen, ob es andere Möglichkeiten gibt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Ich will nicht, dass es aussieht, als sei ich unzuverlässig“',
        phrases: [
          'Genau, Ehrlichkeit hilft hier sehr. Ja, deshalb ist ein offenes Gespräch mit dem Chef sinnvoll. Vielleicht könnt ihr zusammen eine Lösung finden, die für alle passt.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Gleitzeit oder später anfangen“',
        phrases: [
          'Ja, das könnte eine gute Lösung sein. Stimmt, so bleibt die Arbeit fair verteilt. Das ist oft die beste Möglichkeit, Stress zu vermeiden.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st65',
    number: 65,
    stimulus: 'Ich möchte gerne mal einen Bildungsurlaub machen. Weißt du, wie das bei uns in der Firma geregelt ist?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, soweit ich weiß, kann man dafür ein oder zwei Wochen im Jahr freinehmen, wenn der Kurs anerkannt ist.'),
      DialogLine(isPersonA: true, text: 'Ah, das ist gut zu wissen. Muss man den Bildungsurlaub vorher genehmigen lassen?'),
      DialogLine(isPersonA: false, text: 'Ja, man sollte rechtzeitig mit dem Chef oder der Personalabteilung sprechen, damit alles offiziell ist.'),
      DialogLine(isPersonA: true, text: 'Verstehe. Gibt es bestimmte Kurse, die anerkannt sind?'),
      DialogLine(isPersonA: false, text: 'Ja, meistens Weiterbildungen, die fachlich oder beruflich relevant sind. Sprachkurse, Managementseminare oder ähnliche Themen werden oft akzeptiert.'),
      DialogLine(isPersonA: true, text: 'Das klingt interessant. Ich würde gern einen Sprachkurs machen, um meine Chancen im Job zu verbessern.'),
      DialogLine(isPersonA: false, text: 'Gute Idee. Ich habe gehört, dass man für Sprachkurse sogar die Kosten zum Teil erstattet bekommt.'),
      DialogLine(isPersonA: true, text: 'Super, dann muss ich mich mal informieren und einen Antrag stellen.'),
      DialogLine(isPersonA: false, text: 'Ja, und am besten frühzeitig planen, damit es in deinen Arbeitsplan passt. Dann klappt alles problemlos.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Weißt du, wie das geregelt ist?“',
        phrases: [
          'Ja, ich glaube, man kann ein bis zwei Wochen Bildungsurlaub pro Jahr nehmen.',
          'Ich bin mir nicht sicher, aber ich kann für dich nachschauen. Meines Wissens muss der Kurs anerkannt sein, dann geht es. Du musst vorher bei der Personalabteilung nachfragen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Muss man den Bildungsurlaub vorher genehmigen lassen?“',
        phrases: [
          'Ja, unbedingt, damit der Chef informiert ist. Genau, sonst kann es später Probleme geben. Meistens reicht ein kurzer Antrag bei der Personalabteilung.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Gibt es bestimmte Kurse?“',
        phrases: [
          'Ja, meistens Kurse, die beruflich oder fachlich relevant sind. Ich glaube, Sprachkurse oder Managementseminare werden akzeptiert. Am besten vorher prüfen, ob der Kurs offiziell anerkannt ist.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Kosten teilweise erstattet“',
        phrases: [
          'Ja, das ist ein zusätzlicher Vorteil. Stimmt, manchmal übernimmt die Firma einen Teil der Gebühren. Ich würde mich vorher informieren, wie viel genau erstattet wird.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st66',
    number: 66,
    stimulus: 'Unsere Abteilung plant, in ein Kochstudio zu gehen, um gemeinsam zu kochen. Mir gefällt diese Idee. Wie findest du sie?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ich finde die Idee auch super. So kann man das Team auf eine ganz andere Weise kennenlernen.'),
      DialogLine(isPersonA: true, text: 'Genau, es ist mal etwas anderes als ein normales Meeting oder Seminar.'),
      DialogLine(isPersonA: false, text: 'Außerdem macht es Spaß, gemeinsam etwas zu schaffen und hinterher das Essen zu genießen.'),
      DialogLine(isPersonA: true, text: 'Ja, das gemeinsame Kochen stärkt bestimmt den Zusammenhalt.'),
      DialogLine(isPersonA: false, text: 'Stimmt, und man lernt vielleicht auch ein paar neue Rezepte.'),
      DialogLine(isPersonA: true, text: 'Denkst du, dass jeder mitmachen wird, auch diejenigen, die nicht so gern kochen?'),
      DialogLine(isPersonA: false, text: 'Ich glaube schon, die meisten werden es interessant finden. Und wer weniger Spaß am Kochen hat, kann trotzdem zusehen und die Atmosphäre genießen.'),
      DialogLine(isPersonA: true, text: 'Das stimmt. Vielleicht könnten wir danach noch ein kleines Teamspiel oder Quiz machen, damit es abwechslungsreich bleibt.'),
      DialogLine(isPersonA: false, text: 'Gute Idee, dann wird der Abend richtig unterhaltsam und bleibt allen in Erinnerung.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Wie findest du sie?“',
        phrases: [
          'Ich finde die Idee toll, das wird sicher Spaß machen. Ich mag die Idee, es ist mal etwas anderes als ein normaler Arbeitstag. Eigentlich interessant, ich bin gespannt, wie es abläuft. Ich weiß noch nicht, ich koche nicht so gern, aber es könnte trotzdem lustig sein.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Das stärkt den Zusammenhalt“',
        phrases: [
          'Ja, genau, gemeinsame Aktivitäten verbinden das Team.',
          'Stimmt, so lernt man Kollegen von einer anderen Seite kennen. Das sehe ich auch, aber manche sind vielleicht schüchtern.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Jeder wird mitmachen?“',
        phrases: [
          'Wahrscheinlich, die meisten finden das spannend. Ich hoffe, dass alle dabei sind, sonst fehlt die Teamatmosphäre. Es wird sicher nicht jeder begeistert sein, aber die Mehrheit wird Spaß haben.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Teamspiel oder Quiz danach“',
        phrases: [
          'Ja, das klingt nach einem guten Plan, so bleibt es abwechslungsreich. Genau, ein kleines Spiel macht den Abend locker und lustig. Stimmt, das rundet den Abend schön ab.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st67',
    number: 67,
    stimulus: 'Weißt du schon, wohin du in den Urlaub fährst? Bist du auf die Schulferien angewiesen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, ich plane, nach Italien zu fahren. Ich muss auf die Schulferien meiner Kinder achten, sonst klappt es nicht.'),
      DialogLine(isPersonA: true, text: 'Ah, das verstehe ich. Ferien mit Kindern müssen gut geplant werden.'),
      DialogLine(isPersonA: false, text: 'Genau, besonders wegen der Unterkünfte, die oft früh ausgebucht sind.'),
      DialogLine(isPersonA: true, text: 'Ich bin etwas flexibler, ich kann auch außerhalb der Ferien fahren. Dann ist es meist ruhiger und günstiger.'),
      DialogLine(isPersonA: false, text: 'Stimmt, das wäre ein Vorteil. Aber für mich ist es wichtiger, dass die Kinder frei haben.'),
      DialogLine(isPersonA: true, text: 'Machst du dann immer dieselbe Art von Urlaub, oder probierst du auch Neues aus?'),
      DialogLine(isPersonA: false, text: 'Meistens Strandurlaub, aber dieses Jahr wollen wir auch ein bisschen Kultur machen.'),
      DialogLine(isPersonA: true, text: 'Das klingt interessant. So ist es abwechslungsreich und alle haben Spaß.'),
      DialogLine(isPersonA: false, text: 'Genau, das ist das Wichtigste. Und du, wohin fährst du dieses Jahr?'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Bist du auf die Schulferien angewiesen?“',
        phrases: [
          'Ja, ich muss die Ferien meiner Kinder beachten. Nein, ich kann flexibel reisen, da ich keine Kinder habe. Nur teilweise, manchmal nehme ich ein paar Tage früher frei. Ja, sonst würde es mit der ganzen Familie schwierig werden.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Ah, das verstehe ich“',
        phrases: [
          'Ja, es muss gut geplant sein, sonst klappt es nicht. Genau, Unterkünfte sind oft schon Monate vorher ausgebucht. Stimmt, besonders bei beliebten Urlaubszielen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Machst du immer dieselbe Art von Urlaub?“',
        phrases: [
          'Meistens, aber manchmal probieren wir Neues aus. Nein, wir wechseln zwischen Strand und Aktivurlaub. Ich mag es, neue Länder zu entdecken, daher variiere ich jedes Jahr.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „So ist es abwechslungsreich“',
        phrases: [
          'Ja, alle sind zufrieden, und jeder hat etwas davon. Genau, dann wird der Urlaub nicht langweilig. Stimmt, Abwechslung macht die Reise interessant.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st68',
    number: 68,
    stimulus: 'In der Kantine kann man nur noch abgepackte Brötchen kaufen. Ich würde gerne eine warme Mahlzeit essen. Wie ist das bei dir?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das finde ich auch schade. Früher gab es viel mehr Auswahl an warmen Gerichten.'),
      DialogLine(isPersonA: true, text: 'Genau, manchmal habe ich richtig Lust auf ein warmes Mittagessen, besonders an kalten Tagen.'),
      DialogLine(isPersonA: false, text: 'Stimmt, abgepackte Brötchen sind schnell, aber sie sättigen nicht so gut.'),
      DialogLine(isPersonA: true, text: 'Ich frage mich, ob die Kantine wieder warme Mahlzeiten einführt oder ob das dauerhaft so bleibt.'),
      DialogLine(isPersonA: false, text: 'Vielleicht liegt es an den Kosten oder an der Organisation. Die Firma möchte wahrscheinlich sparen.'),
      DialogLine(isPersonA: true, text: 'Das kann sein. Aber es wäre schön, wenn man wenigstens einmal in der Woche ein warmes Gericht hätte.'),
      DialogLine(isPersonA: false, text: 'Ja, oder man könnte kleine Optionen anbieten, wie Suppe oder ein warmes Sandwich.'),
      DialogLine(isPersonA: true, text: 'Genau, das wäre ein guter Kompromiss, dann bleiben die Preise niedrig und alle sind zufrieden.'),
      DialogLine(isPersonA: false, text: 'Ich hoffe, dass die Kantine darauf eingeht. Vielleicht könnten wir auch einen Vorschlag machen.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Wie ist das bei dir?“',
        phrases: [
          'Ich finde es auch schade, ich vermisse die warmen Mahlzeiten. Mir ist es egal, ich esse oft nur kleine Snacks. Ich esse lieber etwas Schnelles, daher passt es für mich. Ja, ich hätte auch gerne wieder warme Gerichte.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Früher gab es mehr Auswahl“',
        phrases: [
          'Genau, die Auswahl war abwechslungsreicher und gesünder. Stimmt, es war angenehmer, etwas Warmes zu essen. Ja, das hat die Mittagspause schöner gemacht.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Vielleicht liegt es an den Kosten…“',
        phrases: [
          'Ja, das ist wahrscheinlich. Das kann sein, aber ein kleiner Teil warmes Essen sollte möglich sein. Stimmt, aber man könnte trotzdem ab und zu etwas Warmes anbieten.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Vielleicht könnten wir einen Vorschlag machen“',
        phrases: [
          'Ja, das wäre gut, dann zeigt die Kantine, dass die Mitarbeitenden interessiert sind. Genau, Vorschläge helfen manchmal, die Situation zu verbessern. Wir könnten auch eine kleine Umfrage starten, um zu sehen, was die meisten möchten.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st69',
    number: 69,
    stimulus: 'Als neues Angebot für eine aktive Pause gibt es jetzt Tischtennis. Wollen wir mal in der Pause spielen?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, das klingt super. Ich spiele gern ein bisschen Tischtennis, das ist eine gute Abwechslung.'),
      DialogLine(isPersonA: true, text: 'Genau, es macht Spaß und man kann sich kurz bewegen, statt nur zu sitzen.'),
      DialogLine(isPersonA: false, text: 'Stimmt. Außerdem kann man so kurz vom Arbeitsstress abschalten.'),
      DialogLine(isPersonA: true, text: 'Denkst du, dass viele Kollegen mitmachen werden?'),
      DialogLine(isPersonA: false, text: 'Ich glaube schon, manche sind sicher motiviert, andere sind eher weniger sportlich.'),
      DialogLine(isPersonA: true, text: 'Vielleicht könnten wir kleine Spiele oder Turniere organisieren, dann wird es interessanter.'),
      DialogLine(isPersonA: false, text: 'Gute Idee. So motiviert man vielleicht auch die, die sonst nicht spielen würden.'),
      DialogLine(isPersonA: true, text: 'Wir könnten auch festlegen, dass jeder mal gegen jeden spielt, dann bleibt es fair.'),
      DialogLine(isPersonA: false, text: 'Ja, das macht den Spaß aus und man hat danach gute Laune für die restliche Arbeit.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Wollen wir mal spielen?“',
        phrases: [
          'Ja, sehr gern! Das klingt nach Spaß. Ich weiß noch nicht, vielleicht probiere ich es einmal aus. Nein, Tischtennis ist nicht so mein Ding, aber ihr könnt spielen. Klar, eine kurze Pause mit Bewegung ist super.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Man kann kurz vom Arbeitsstress abschalten“',
        phrases: [
          'Ja, genau, so tankt man Energie für den Nachmittag. Stimmt, Bewegung hilft, den Kopf frei zu bekommen. Ich finde es eine gute Idee, um die Pause aktiver zu gestalten.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Viele Kollegen machen mit?“',
        phrases: [
          'Ich glaube, ja, besonders die sportlichen. Vielleicht nur ein paar, aber besser als nichts. Manche werden sicher skeptisch sein, aber wer mitmacht, hat Spaß.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Kleine Spiele oder Turniere organisieren?“',
        phrases: [
          'Ja, das motiviert alle und macht mehr Spaß. Genau, so bleibt es abwechslungsreich und fair. Gute Idee, dann hat jeder die Chance zu spielen',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st70',
    number: 70,
    stimulus: 'Die Firma plant einen Betriebsausflug über das ganze Wochenende. Was hältst du davon?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ehrlich gesagt, ich bin etwas zwiegespalten. Ein Wochenende ist lang, da muss man sich schon Zeit nehmen.'),
      DialogLine(isPersonA: true, text: 'Ja, das stimmt. Es wäre schön, wenn man genug Zeit hätte, aber nicht jeder kann das ganze Wochenende frei machen.'),
      DialogLine(isPersonA: false, text: 'Genau, manche Kollegen haben Familie oder andere Verpflichtungen.'),
      DialogLine(isPersonA: true, text: 'Auf der anderen Seite ist es sicher eine tolle Möglichkeit, das Team besser kennenzulernen und gemeinsame Aktivitäten zu machen.'),
      DialogLine(isPersonA: false, text: 'Ja, da stimme ich zu. Ein längerer Ausflug kann den Zusammenhalt stärken.'),
      DialogLine(isPersonA: true, text: 'Vielleicht könnte man vorher eine Umfrage machen, wer teilnehmen möchte, damit keiner überrumpelt wird.'),
      DialogLine(isPersonA: false, text: 'Gute Idee. Dann bleibt es freiwillig und jeder entscheidet selbst.'),
      DialogLine(isPersonA: true, text: 'Außerdem könnte man verschiedene Programmpunkte planen, damit für jeden etwas dabei ist.'),
      DialogLine(isPersonA: false, text: 'Stimmt, dann wird das Wochenende abwechslungsreich und alle haben Spaß.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Was hältst du davon?“',
        phrases: [
          'Ich finde es interessant, aber ein ganzes Wochenende ist lang. Ich bin nicht sicher, ob ich teilnehmen kann, wegen Familie oder anderen Verpflichtungen. Ich finde die Idee gut, längere Ausflüge stärken das Team. Es klingt spannend, aber ich hoffe, es ist freiwillig.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Tolle Möglichkeit, das Team kennenzulernen“',
        phrases: [
          'Ja, man lernt die Kollegen von einer anderen Seite kennen. Stimmt, besonders bei gemeinsamen Aktivitäten ist das effektiv. Ich finde, kurze Ausflüge sind oft einfacher, aber ein Wochenende kann auch gut sein.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Umfrage vorher machen“',
        phrases: [
          'Ja, so kann jeder selbst entscheiden. Genau, das wäre fair für alle Beteiligten. Gute Idee, dann wird niemand gezwungen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Verschiedene Programmpunkte“',
        phrases: [
          'Ja, so bleibt es abwechslungsreich und interessant. Genau, dann ist für jeden etwas dabei, auch für weniger sportliche Kollegen. Stimmt, so kann man den Ausflug individuell gestalten.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st71',
    number: 71,
    stimulus: 'Hast du eine Idee, was man in den Ferien mit Kindern hier in der Stadt unternehmen kann?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Ja, es gibt einige Möglichkeiten. Man könnte ins Museum gehen, viele Museen haben spezielle Kinderführungen.'),
      DialogLine(isPersonA: true, text: 'Stimmt, das ist eine gute Idee, so lernen die Kinder spielerisch etwas Neues.'),
      DialogLine(isPersonA: false, text: 'Oder man geht in den Zoo oder Tierpark. Kinder lieben Tiere, und es ist gleichzeitig ein schöner Spaziergang.'),
      DialogLine(isPersonA: true, text: 'Ja, das gefällt ihnen sicher. Gibt es auch Outdoor-Angebote, die man machen könnte?'),
      DialogLine(isPersonA: false, text: 'Auf jeden Fall. Parks, Spielplätze oder auch Fahrrad- und Bootsverleih am See sind tolle Optionen.'),
      DialogLine(isPersonA: true, text: 'Und bei schlechtem Wetter?'),
      DialogLine(isPersonA: false, text: 'Dann könnte man in die Stadtbibliothek gehen oder einen Indoor-Spielplatz besuchen. Viele bieten auch kreative Workshops an.'),
      DialogLine(isPersonA: true, text: 'Das klingt perfekt. Ich denke, wir müssen einfach eine Mischung aus drinnen und draußen planen, dann ist für alle etwas dabei.'),
      DialogLine(isPersonA: false, text: 'Genau, so bleibt es abwechslungsreich und die Kinder werden nicht gelangweilt.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Hast du eine Idee…?“',
        phrases: [
          'Ja, man könnte ins Museum oder Planetarium gehen. Vielleicht in den Zoo oder Tierpark, das kommt immer gut an. Parks, Spielplätze oder Fahrradtouren sind auch schöne Möglichkeiten. Indoor-Spielplätze oder Workshops sind gut, wenn das Wetter schlecht ist.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „So lernen die Kinder spielerisch etwas Neues“',
        phrases: [
          'Genau, das ist eine tolle Mischung aus Spaß und Bildung. Stimmt, so wird es nicht langweilig. Ich finde, Kinder lernen am besten durch praktische Erlebnisse.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Outdoor-Angebote“',
        phrases: [
          'Ja, Fahrradtouren oder Bootsverleih am See machen viel Spaß. Spielplätze oder Parks sind perfekt für jüngere Kinder. Auch ein Picknick im Park kann eine schöne Idee sein.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Mischung aus drinnen und draußen“',
        phrases: [
          'Genau, dann ist für jedes Wetter und jeden Geschmack etwas dabei. Stimmt, so bleibt der Tag abwechslungsreich und interessant. Das ist eine gute Lösung, dann werden die Kinder nicht müde oder gelangweilt.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st72',
    number: 72,
    stimulus: 'Weißt du schon, was du für unsere Weihnachtsfeier anziehst? Sie findet schon nächste Woche statt.',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Noch nicht ganz. Ich überlege, etwas Festliches, aber nicht zu formell.'),
      DialogLine(isPersonA: true, text: 'Ja, das ist gut. Es soll ja gemütlich bleiben, aber trotzdem ein bisschen feierlich.'),
      DialogLine(isPersonA: false, text: 'Genau. Vielleicht ein schönes Kleid oder ein schicker Pullover. Und du?'),
      DialogLine(isPersonA: true, text: 'Ich denke über eine Bluse mit Rock oder eine Kombination mit Hose nach. Es soll bequem sein, aber auch passend für die Feier.'),
      DialogLine(isPersonA: false, text: 'Ja, Komfort ist wichtig, besonders wenn es ein längerer Abend wird.'),
      DialogLine(isPersonA: true, text: 'Denkst du, dass wir uns nach dem Dresscode richten sollten, den die Firma vorgeschlagen hat?'),
      DialogLine(isPersonA: false, text: 'Ich glaube schon, ein bisschen orientieren schadet nicht. So wirkt es professionell und festlich zugleich.'),
      DialogLine(isPersonA: true, text: 'Stimmt, und man kann trotzdem persönliche Akzente setzen, zum Beispiel mit Schmuck oder Accessoires.'),
      DialogLine(isPersonA: false, text: 'Ja, das macht den Look individuell und trotzdem passend für die Feier.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf „Weißt du schon, was du anziehst?“',
        phrases: [
          'Noch nicht genau, ich überlege noch etwas Festliches. Ich denke über einen schicken Pullover oder ein Kleid nach. Ich habe noch keine Idee, vielleicht orientiere ich mich am Dresscode. Ich möchte etwas Bequemes, aber trotzdem festlich tragen.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Es soll gemütlich bleiben“',
        phrases: [
          'Genau, man soll sich wohlfühlen. Stimmt, es soll nicht zu formell sein. Ja, bequem und festlich zugleich ist ideal.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Denkst du, wir sollen uns am Dresscode orientieren?“',
        phrases: [
          'Ja, ein bisschen Orientierung schadet nicht. Genau, so wirkt es professionell und trotzdem festlich. Ich glaube, die meisten werden sich daran halten, das ist sicher gut.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf „Persönliche Akzente setzen“',
        phrases: [
          'Ja, Schmuck oder schöne Accessoires machen viel aus. Genau, so wird der Look individuell. Stimmt, das verleiht dem Outfit eine persönliche Note.',
        ],
      ),
    ],
  ),
  SmalltalkExercise(
    id: 'st73',
    number: 73,
    stimulus: 'Ich finde flexible Arbeitszeiten großartig. Wann fängst du morgens mit der Arbeit an?',
    dialogue: [
      DialogLine(isPersonA: false, text: 'Normalerweise gegen 8 Uhr, aber manchmal auch später, je nachdem, wie es passt.'),
      DialogLine(isPersonA: true, text: 'Ah, das ist praktisch. Ich starte meistens um 7:30 Uhr, dann habe ich den Nachmittag frei.'),
      DialogLine(isPersonA: false, text: 'Das ist ein Vorteil, man kann die Arbeit gut an den eigenen Rhythmus anpassen.'),
      DialogLine(isPersonA: true, text: 'Ja, und wenn man morgens länger schläft, kann man trotzdem später anfangen und die Stunden später nachholen.'),
      DialogLine(isPersonA: false, text: 'Genau. Außerdem ist es angenehm, wenn man private Termine flexibel legen kann.'),
      DialogLine(isPersonA: true, text: 'Denkst du, dass flexible Arbeitszeiten die Produktivität erhöhen?'),
      DialogLine(isPersonA: false, text: 'Ja, ich glaube schon. Wenn man selbst entscheiden kann, wann man arbeitet, ist man oft motivierter.'),
      DialogLine(isPersonA: true, text: 'Stimmt, und es verringert den Stress, besonders wenn der Arbeitsweg lang ist oder Zugprobleme auftreten.'),
      DialogLine(isPersonA: false, text: 'Absolut. Flexible Zeiten sind für viele Mitarbeiter ein großer Vorteil.'),
    ],
    alternatives: [
      SmalltalkAlternatives(
        label: 'Auf "Wann fängst du morgens an?"',
        phrases: [
          'Meistens um 8 Uhr, manchmal später, je nach Bedarf.',
          'Ich starte oft um 7:30 Uhr, aber manchmal auch flexibel.',
          'Es hängt vom Tag ab, manchmal fange ich 9 Uhr an.',
          'Ich nutze die Flexibilität und passe meine Arbeitszeiten an Termine an.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf "Praktisch" / Vorteile der Flexibilität',
        phrases: [
          'Ja, man kann Arbeit und Privatleben besser kombinieren.',
          'Genau, es ist angenehmer, wenn man den Tag selbst einteilen kann.',
          'Stimmt, so bleibt mehr Zeit für Familie oder Hobbys.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf "Produktivität erhöhen?"',
        phrases: [
          'Ja, Motivation steigt, wenn man selbst entscheiden kann.',
          'Genau, weniger Stress bedeutet oft bessere Leistung.',
          'Ich denke schon, viele arbeiten konzentrierter, wenn sie flexibel starten können.',
        ],
      ),
      SmalltalkAlternatives(
        label: 'Auf "Stress verringern"',
        phrases: [
          'Stimmt, besonders bei langen Arbeitswegen oder unzuverlässigen Zügen.',
          'Ja, das macht den Alltag entspannter.',
          'Genau, flexible Arbeitszeiten sind eine echte Entlastung.',
        ],
      ),
    ],
  ),

];
