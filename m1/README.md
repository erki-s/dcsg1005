# Beskyttelse mot ransomware med Powershell

[[_TOC_]]

## Målet med prosjektet

Målet med prosjektet er å lage et script som beskytter mot ransomware. En ganske sikker måte å sikre at absolutt alle filene ikke blir låst av ransomware, er å lage backupfiler, slik at når de originale filene faktsik blir låst, finnes backupfiler som kan bli gjenopprettet når som helst. For å være enda sikrere på at brukeren av scriptet skal ha tilgang til i hvert fall en backup, var målet også en metode som hjelper med dette, som i dette tilfellet ble 3-2-1 regelen. Jeg ville også legge til noen andre funksjonaliteter i tillegg til bare backup-scriptet. Disse endte opp med å bli funksjonaliteter som kan både forebygge mot ransomware og beskytte mot spredning av det.

## Design / Løsning

Før jeg begynte å skrive scriptet, planla jeg å lage backup scriptet etter 3-2-1 regelen. Etter å ha lært om 3-2-1 regelen fra Cybersikkerhet og teamarbeid i høst, så det ut til å være en veldig enkel måte å backupe på, i tillegg til at det ser ut til å være ganske sikkert. Regelen går ut på å lage 3 kopier lokalt, 2 kopier på andre enheter, og 1 så langt borte som mulig, altså ved for eksempel cloud-lagring som OneDrive.

Backup-scriptet kjører hver halvtime, som for meg virker ofte nok for å beskytte fra angrep uten å miste en alt for stor mengde med data. Denne tiden kan enkelt bli endret når som helst ved å endre på New-TimeSpan i New-ScheduledTaskTrigger. For å lage en scheduled task, leste jeg [denne nettsiden](https://adamtheautomator.com/powershell-scheduled-task/) som Erik anbefalte for å lage en enkel scheduled task. For å kjøre scriptet som administrator, fant jeg fram til [dette](https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskprincipal?view=win10-ps) som forklarte hvordan jeg gjør det.

Når det kom til å lage restore script, så jeg ikke noe stor grunn for å lage det. Backupene lages bare for det tilfellet der det verste skjer og de originale filene skades. Med løsningen jeg har laget, er det veldig enkelt å finne fram til backupene og kopiere de over til arbeidsområdet igjen. Et problem med restore script er også at hvis jeg skal kun lage en fil, ser jeg ikke noe lett måte å holde scriptet automatisk på. Kanskje en måte å gjøre det inni kun en fil er å lage en variabel som kan bli endret, men det er like enkelt å kopiere filene. Hadde jeg laget et restore-script, hadde koden vært så enkel som at filene fra en backup-mappe kopieres tilbake til arbeidsområdet. Den kunne kanskje hatt menyvalg ved hjelp av variabler, slik at brukeren kan velge hvilken mappe backupen skal kopieres fra.

Det samme er med delen av scriptet som skal bruke Compare-Object som vi fikk et eksempel av fra Erik. For den måten scriptet mitt funker/skal bli brukt på, ser jeg ikke noe grunn for å sjekke om filene i backup-mappene er nyere. Når jeg tenker på hvordan scriptet skal brukes, tenker jeg på at de som arbeider med filene, lagrer dem i arbeidsområdet og ikke i backup-mappene. Eneste tilfellet der det kanskje hjelper er når flere folk arbeider med de samme filene, men dette hadde uansett gitt problemer. De hadde overskrevet filene som de jobber med, selv om de har jobbet mer eller mindre, så lenge filen er nyere.

Delen av scriptet som kopierer filene bruker også Force parameteret, som gjør at Copy-Item også kopierer over filer som ellers ikke kunne blitt kopiert over. Dette inkluderer for eksempel filer som er skrivebeskyttet (read-only). [Forklaring av -Force i Copy-Item.](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/copy-item?view=powershell-7.1)

Jeg la til 2 andre funksjonaliteter som kan hjelpe mot ransomware i tillegg til backup-scriptet. Den første skrur bare på brannmuren hver gang scriptet kjøres. Hvis den allerede er på, skjer ingenting (Den skrur på brannmuren som er allerede på). Dette hjelper med å forebygge mot ransomware, i hvert fall i en liten grad. Den andre funksjonaliteten går gjennom filene i arbeidsområdet, altså $source, og sjekker om det eksisterer noen filer inni mappen med extensions som tidligere har blitt brukt for ransomware. Listen som ligger i scriptet inneholder ikke mer enn noen få, men en stor liste av disse kan bli funnet [her](https://avepointcdn.azureedge.net/assets/webhelp/compliance_guardian_installation_and_administration/index.htm#!Documents/ransomwareencryptedfileextensionlist.htm). Grunnen til at jeg la til denne delen av scriptet, er for å hjelpe med å hindre spredning av ransomware mellom enheter i et nettverk ved å ta bort den påvirkede enheten fra dette nettverket.

## Fordeler, ulemper og sikkerhet

Scriptet er ganske enkelt for brukeren å sette opp, siden det eneste de trenger å gjøre er å endre filplasseringene. Etter scriptet er helt satt opp, trenger ikke brukeren lenger å gjøre noe etterpå.

En negativ side med scriptet er at når det kjøres, åpnes powershell hver gang scriptet kjøres. Etter å ha aktivert innstilligen "Hidden" i Task Scheduler og etter å ha søkt på nettet etter en løsning på dette, fikk jeg ikke scriptet til å kjøre skjult i bakgrunnen. Det eneste jeg kom fram til etter å ha søkt etter det var at kanskje det krever bruk av [tredjepartisutvidelser](https://stackoverflow.com/a/1802183) som jeg ikke hadde lyst til å bruke (Fortsatt litt usikker på om jeg faktisk trenger det).

Løsningen her inneholder ingen passord som kreves for at scriptet skal kjøres. Hvis noen hadde fått tak i scriptet ubevisst for den originale brukeren, hadde dette passordet vært utsatt. Dette kan inneholde passord til ulike enheter eller cloudtjenester. 

Et større problem med scriptet er at den blir automatisk kjørt som administrator. Dette gir scriptet tilgang til å gjøre større endringer på maskinen, som for eksempel i scriptet mitt er Set-NetFirewallProfile og deler av mounting/unmounting. Hadde det på en eller annen måte blitt gjort endringer på scriptet, ubevisst for brukeren, kunne de har kjørt et script som kan utføre uønskede kommandoer, eller til og med skade enheten.

Brukeren selv har en veldig lav sannsynlighet for å bruke scriptet feil, fordi det eneste som må endres er filplasseringene, mens resten av scriptet finner selv fram til disknummere osv. 

## Konklusjon og refleksjon

For å konkludere, tror jeg at jeg laget et script som på en pålitelig måte kopierer filer for å lage backups. Jeg hadde en ferdig plan nesten fra starten av, mens de to ekstra funksjonalitetene kom jeg på senere. Scriptet lagrer backups på flere måter, og følger 3-2-1 regelen, og sikrer derfor at det vil være i hvert fall noen backupfiler igjen. Jeg brukte for det meste kunnskapene fra timene vi har hatt, i tillegg til å bruke nettet. Som jeg forstår har jeg oppnådd hovedmålet med oppgaven, som var å lage backupfiler fra et arbeidsområte. I tillegg har jeg nådd andre mål som å finne på noen andre løsninger som brannmuren og nettverksadapterne som jeg har nevnt tidligere. Å finne ut hvordan jeg kjører scriptet som administrator hver gang tok ganske lang tid å finne ut, men heldigvis til slutt fant jeg ut av det, og kom fram til et backup-script som jeg ble fornøyd med.


Kilder som jeg brukte: 

[Scheduled tasks](https://adamtheautomator.com/powershell-scheduled-task/)

[Scheduled task principal](https://docs.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskprincipal?view=win10-ps)

[Ransomware extensions](https://avepointcdn.azureedge.net/assets/webhelp/compliance_guardian_installation_and_administration/index.htm#!Documents/ransomwareencryptedfileextensionlist.htm)

[Task scheduler hidden window](https://stackoverflow.com/a/1802183)

[Mounting/Unmounting](https://gitlab.com/erikhje/dcsg1005/-/blob/master/powershell.md#mounting-and-unmounting-disks)

