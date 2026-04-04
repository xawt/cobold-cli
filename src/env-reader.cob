      *================================================================*
      * PROGRAM:     ENV-READER                                        *
      * DESCRIPTION: Reads API key and model name from a .env file     *                                              *
      * DATE:        2026-04-04                                        *
      *----------------------------------------------------------------*
      * CHANGES:                                                       *
      *   2026-04-04    Initial version                                *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ENV-READER.
      *> CALL "ENV-READER" USING api-key, model

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ENV-FILE
               ASSIGN TO DYNAMIC WS-ENV-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ENV-FILE.
       01  ENV-RECORD              PIC X(500).

       WORKING-STORAGE SECTION.
       01  WS-ENV-PATH             PIC X(500).
       01  WS-FILE-STATUS          PIC XX.
       01  WS-EOF                  PIC X.
       01  WS-SLASH-POS            PIC 9(4).
       01  WS-PATH-LEN             PIC 9(4).
       01  WS-KEY                  PIC X(100).
       01  WS-VALUE                PIC X(400).

       01  WS-EXE-PATH             PIC X(500).

       LINKAGE SECTION.
       01  LK-API-KEY              PIC X(300).
       01  LK-MODEL                PIC X(100).

       PROCEDURE DIVISION USING LK-API-KEY, LK-MODEL.

       MAIN-PARA.
           PERFORM GET-ENV-PATH
           PERFORM READ-ENV-FILE
           GOBACK.

       GET-ENV-PATH.
           ACCEPT WS-EXE-PATH FROM ENVIRONMENT "_"
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-EXE-PATH, TRAILING))
               TO WS-PATH-LEN
           MOVE 0 TO WS-SLASH-POS
           INSPECT FUNCTION REVERSE(
               FUNCTION TRIM(WS-EXE-PATH, TRAILING))
               TALLYING WS-SLASH-POS FOR CHARACTERS BEFORE '/'
           IF WS-SLASH-POS = WS-PATH-LEN
               MOVE "./.env" TO WS-ENV-PATH
           ELSE
               STRING WS-EXE-PATH(1:WS-PATH-LEN - WS-SLASH-POS)
                   ".env" DELIMITED SIZE INTO WS-ENV-PATH
           END-IF.

       READ-ENV-FILE.
           MOVE 'N' TO WS-EOF
           OPEN INPUT ENV-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "Warning: could not open "
                   FUNCTION TRIM(WS-ENV-PATH)
               GOBACK
           END-IF
           PERFORM UNTIL WS-EOF = 'Y'
               READ ENV-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       PERFORM PARSE-LINE
               END-READ
           END-PERFORM
           CLOSE ENV-FILE.

       PARSE-LINE.
           IF ENV-RECORD = SPACES OR ENV-RECORD(1:1) = '#'
               EXIT PARAGRAPH
           END-IF
           MOVE SPACES TO WS-KEY, WS-VALUE
           UNSTRING ENV-RECORD DELIMITED BY '='
               INTO WS-KEY, WS-VALUE
           END-UNSTRING
           EVALUATE FUNCTION TRIM(WS-KEY)
               WHEN "OPENROUTER_API_KEY"
                   MOVE FUNCTION TRIM(WS-VALUE) TO LK-API-KEY
               WHEN "OPENROUTER_MODEL"
                   MOVE FUNCTION TRIM(WS-VALUE) TO LK-MODEL
           END-EVALUATE.
