       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOLD-CLI.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-API-KEY          PIC X(300).
       01  WS-MODEL            PIC X(100).

       PROCEDURE DIVISION.

       MAIN-PARA.
           CALL "ENV-READER" USING WS-API-KEY, WS-MODEL

           DISPLAY "Hello from cobold-cli!"
           DISPLAY "  API key : " FUNCTION TRIM(WS-API-KEY)
           DISPLAY "  Model   : " FUNCTION TRIM(WS-MODEL)

           STOP RUN.
