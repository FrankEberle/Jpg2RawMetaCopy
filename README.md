# Jpg2RawMetaCopy Lightoom Classic Plugin 

Copyright 2023 by Frank Eberle (https://www.frank-eberle.de)

**Achtung:** Der Autor übernimmt keine Haftung für Probleme, die eventuell durch die Verwendung des Plugins entstehen.
Bitte vor der Verwendung den Lightroom-Katalog sichern (sollte man ohnehin immer machen)!!!

## Installation
1. ZIP-Package von [GitHub](https://github.com/FrankEberle/Jpg2RawMetaCopy/releases) herunterladen
2. Verzeichnis *Jpg2RawMetaCopy.lrplugin* aus ZIP an beliebiger Stelle entpacken
3. Lightroom starten und *Datei > Zusatumodul-Manager* aufrufen
4. *Hinzufügen* Button drücken und Verzeichnis *Jpg2RawMetaCopy.lrplugin* auswählen

Alternative Repository von GitHub clonen und Verzeichnis in *Jpg2RawMetaCopy.lrplugin* umbenennen.

## Verwendung
1. In der Bibliothek Bilder auswählen, wenn keine Bilder gewählt wurden, wird der aktuelle Filmstreifen verwendet
2. *Bibliothek > Zusatzmoduloptionen > Jpg2RawMetaCopy > Copy Meta Data* aufrufen
3. Im Dialog die gewünschten Optionen auswählen und *OK* drücken

## Funktionsweise
Das Plugin sucht in den ausgewählen Bildern (oder dem aktuellen Filmsteifen falls keine Bilder ausgewählt sind) nach JPEG-Bildern.
Für jedes gefundene Bild wird nach einem entsprechenden RAW- oder DNG-Bild gesucht. Hierbei wird nach Bildern gesucht, die den gleichen
Basisnamen haben. Für jede entsprechende RAW- bzw. DNG-Datei werden die ausgewählten Meta-Daten kopiert.

## Unterstützte Meta-Daten
* Bewertung (Sterne)
* Farb-Label
* Titel
* Bildunterschrift (Caption)
* Copyright
* Flagge (ausgewählt, abgelehnt)
* Schlagworte
* GPS-Daten (Koordinaten und Höhe)

## Kopieren der Entwicklungs-Einstellungen
Neben den Meta-Daten kann das Plugin ebenfalls die Enwicklungs-Einstellungen vom JPEG zum RAW/DNG kopieren. Dies kann beispielsweise dazu genutzt
werden, unterwegs Bearbeitungen in LR Mobile am JPEG zu "skizzieren" und diese später in LR Classic am RAW/DNG zu verfeinern.

