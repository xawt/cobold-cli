      *================================================================*
      * PROGRAM:     WEATHER-TOOL                                      *
      * DESCRIPTION: Fetches current weather for a location via        *
      *              wttr.in and returns a plain-text summary.         *
      *                                                                *
      * CALL "WEATHER-TOOL" USING                                      *
      *   LK-LOCATION  PIC X(100)  -- city/location to look up        *
      *   LK-RESULT    PIC X(500)  -- weather summary (output)        *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WEATHER-TOOL.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT RESP-FILE
               ASSIGN TO '/tmp/cobold_weather.txt'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  RESP-FILE.
       01  RESP-RECORD         PIC X(500).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS      PIC XX.
       01  WS-EOF              PIC X.
       01  WS-CURL-CMD         PIC X(600).
       01  WS-CURL-RC          PIC S9(9) BINARY.
       01  WS-RESULT-PTR       PIC 9(4).
       01  WS-LOCATION-ENC     PIC X(200).
       01  WS-LOC-SRC-IDX      PIC 9(4).
       01  WS-LOC-DST-IDX      PIC 9(4).
       01  WS-LOC-LEN          PIC 9(4).
       01  WS-CHAR             PIC X.

       LINKAGE SECTION.
       01  LK-LOCATION         PIC X(100).
       01  LK-RESULT           PIC X(500).

       PROCEDURE DIVISION USING LK-LOCATION LK-RESULT.

       MAIN-PARA.
           MOVE SPACES TO LK-RESULT
           PERFORM URL-ENCODE-LOCATION
           PERFORM BUILD-CURL-CMD
           PERFORM RUN-CURL
           IF WS-CURL-RC NOT = 0
               MOVE 'error: curl failed fetching weather'
                   TO LK-RESULT
               EXIT PROGRAM
           END-IF
           PERFORM READ-RESPONSE
           EXIT PROGRAM.

      *> Replace spaces with + for URL safety (wttr.in accepts this)
       URL-ENCODE-LOCATION.
           MOVE SPACES TO WS-LOCATION-ENC
           MOVE FUNCTION LENGTH(FUNCTION TRIM(LK-LOCATION))
               TO WS-LOC-LEN
           MOVE 1 TO WS-LOC-DST-IDX
           PERFORM VARYING WS-LOC-SRC-IDX FROM 1 BY 1
                   UNTIL WS-LOC-SRC-IDX > WS-LOC-LEN
               MOVE LK-LOCATION(WS-LOC-SRC-IDX:1) TO WS-CHAR
               IF WS-CHAR = ' '
                   MOVE '+' TO
                       WS-LOCATION-ENC(WS-LOC-DST-IDX:1)
               ELSE
                   MOVE WS-CHAR TO
                       WS-LOCATION-ENC(WS-LOC-DST-IDX:1)
               END-IF
               ADD 1 TO WS-LOC-DST-IDX
           END-PERFORM.

      *> %l=location %t=temp %C=condition text; &A forces plain output
      *> tr strips the degree sign so output is pure ASCII
       BUILD-CURL-CMD.
           MOVE SPACES TO WS-CURL-CMD
           STRING
               "curl -s --max-time 10"
               " 'https://wttr.in/"
               FUNCTION TRIM(WS-LOCATION-ENC)
               "?format=%l:+%t+%C&A'"
               " | tr -d '\302\260'"
               " > /tmp/cobold_weather.txt 2>&1"
               DELIMITED SIZE
               INTO WS-CURL-CMD.

       RUN-CURL.
           CALL "SYSTEM" USING WS-CURL-CMD
               RETURNING WS-CURL-RC.

       READ-RESPONSE.
           MOVE SPACES TO LK-RESULT
           MOVE 1 TO WS-RESULT-PTR
           MOVE 'N' TO WS-EOF
           OPEN INPUT RESP-FILE
           IF WS-FILE-STATUS NOT = "00"
               MOVE 'error: could not open weather response file'
                   TO LK-RESULT
               EXIT PARAGRAPH
           END-IF
           READ RESP-FILE
               AT END
                   MOVE 'error: empty weather response' TO LK-RESULT
               NOT AT END
                   MOVE FUNCTION TRIM(RESP-RECORD) TO LK-RESULT
           END-READ
           CLOSE RESP-FILE.
