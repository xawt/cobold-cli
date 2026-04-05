       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOLD-CLI.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-API-KEY          PIC X(300).
       01  WS-MODEL            PIC X(100).
       01  WS-USER-INPUT       PIC X(1000).

      * ANSI escape sequences (ESC [ ... m)
       01  CLR                 PIC X(4) VALUE X"1B5B306D".
       01  BOLD                PIC X(4) VALUE X"1B5B316D".
       01  DIM                 PIC X(4) VALUE X"1B5B326D".
       01  BLUE                PIC X(5) VALUE X"1B5B33346D".
       01  GREEN               PIC X(5) VALUE X"1B5B33326D".

       PROCEDURE DIVISION.

       MAIN-PARA.
           CALL "ENV-READER" USING WS-API-KEY, WS-MODEL

           DISPLAY BOLD "=========================================" CLR
           DISPLAY BOLD "   cobold-cli  --  AI agent in COBOL    " CLR
           DISPLAY BOLD "=========================================" CLR
           DISPLAY DIM "Model: " FUNCTION TRIM(WS-MODEL) CLR
           DISPLAY " "
           DISPLAY BLUE "you @> " CLR WITH NO ADVANCING
           ACCEPT WS-USER-INPUT

           DISPLAY " "
           DISPLAY GREEN "ai: " CLR FUNCTION TRIM(WS-USER-INPUT)

           STOP RUN.
