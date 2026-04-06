      *================================================================*
      * PROGRAM:     TEST-WEATHER                                      *
      * DESCRIPTION: Standalone test for WEATHER-TOOL.                *
      *                                                                *
      * Build & run:                                                   *
      *   cobc -x src/test-weather.cob src/weather-tool.cob \         *
      *        -o dist/test-weather                                    *
      *   ./dist/test-weather London                                   *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-WEATHER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-LOCATION         PIC X(100).
       01  WS-RESULT           PIC X(500).

       PROCEDURE DIVISION.

       MAIN-PARA.
           ACCEPT WS-LOCATION FROM COMMAND-LINE
           IF FUNCTION TRIM(WS-LOCATION) = SPACES
               DISPLAY "Usage: test-weather <city>"
               STOP RUN
           END-IF
           CALL "WEATHER-TOOL" USING WS-LOCATION WS-RESULT
           DISPLAY FUNCTION TRIM(WS-RESULT)
           STOP RUN.
