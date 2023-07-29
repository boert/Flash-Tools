# romcheck.kcc

Mit diesen Werkzeugen lassen sich zu allen ROM-Modulen bzw. Segementen Prüfsummen und CRC ermitteln.

Als einfache Prüfsumme wird die Summe aller 8-Bit Werte (modulo 2^16) erzeugt (SUM16). Der CRC wird nach CRC16-CCITT gebildet.

Zum Vergleich können die Prüfsummen auch von einem Python-Skript für den PC erzeugt werden. 
![Screenshot](Bilder/flashcheck_pc.png)

Das KC85-Programm enthält folgende Programmmodule:
## ROMSEARCH

ROMSEARCH durchsucht den kompletten KC85 (Mühlhausen-KC85/4 oder KC85/5) nach ROM-Modulen. Wird ein Modul gefunden erfolgt die Ausgabe der Schachtnummer, des Strukturbytes und bei ROM-Modulen der Typ und die Größe.

![Screenshot](Bilder/romsearch.png)

## ROMCHECK

ROMCHECK ermittelt die Prüfsummen über alle Segmente eines Moduls.
Als Parameter wird die Schachtnummer benötigt.

Es erflogt die Ausgabe der Schachtnummer, des Strukturbytes, des Modultypes, sowie von Segmentgröße und Zahl der Segmente.

Beispielausgabe für ein M047 mit 16 ROM Segmenten:
![Screenshot](Bilder/romcheck_M047.png)


Beispielausgabe für ein M052 mit vier ROM Segmenten:
![Screenshot](Bilder/romcheck_M052.png)


## SUM
Mit dem Programm SUM läßt sich die einfache Prüfsumme (SUM16) über einen bestimmten Speicherbereich ermitteln.
Als Parameter werden die Startadresse und die Länge benötigt.
Optional läßt sich ein Startwert angeben. Damit läßt sich die Prüfsumme über mehrere Speicherbereiche ermitteln.
Für das Aktivieren der richtigen Speicherbereiche (SWITCH) ist der Anwender verantwortlich.

Das Beispiel erzeugt die Prüfsumme über den RAM-Bereich von 4000h bis 4FFFh:

```
SUM 4000 1000
```

## CRC
Mit dem Programm CRC läßt sich die Prüfsumme (CRC16) über einen bestimmten Speicherbereich ermitteln.
Als Parameter werden die Startadresse und die Länge benötigt.
Optional läßt sich ein Startwert angeben. Damit läßt sich die Prüfsumme über mehrere Speicherbereiche ermitteln.
Für das Aktivieren der richtigen Speicherbereiche (SWITCH) ist der Anwender verantwortlich.

Das Beispiel erzeugt die CRC-Prüfsumme über den ROM-Bereich von C000h bis DFFFh und verwendet als Startwert 55AAh:

```
CRC C000 2000 55AA
```

