       IDENTIFICATION DIVISION.
       PROGRAM-ID. AI-CALLER.

      *> CALL "AI-CALLER" USING
      *>   LK-API-KEY       PIC X(300)   -- OpenRouter API key
      *>   LK-MODEL         PIC X(100)   -- model identifier
      *>   LK-MESSAGES-JSON PIC X(8000)  -- context array (updated)
      *>   LK-MSG-COUNT     PIC 99       -- turn count (updated)
      *>   LK-RESPONSE      PIC X(2000)  -- extracted assistant text

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PAYLOAD-FILE
               ASSIGN TO '/tmp/cobold_payload.json'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-PAY-STATUS.
           SELECT RESP-FILE
               ASSIGN TO '/tmp/cobold_resp.json'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  PAYLOAD-FILE.
       01  PAYLOAD-RECORD      PIC X(8500).
       FD  RESP-FILE.
       01  RESP-RECORD         PIC X(4000).

       WORKING-STORAGE SECTION.
       01  WS-PAYLOAD          PIC X(8500).
       01  WS-CURL-CMD         PIC X(500).

       01  WS-RESPONSE         PIC X(8000).
       01  WS-RESP-PTR         PIC 9(4).
       01  WS-FILE-STATUS      PIC XX.
       01  WS-PAY-STATUS       PIC XX.
       01  WS-EOF              PIC X.

      *> JSON extraction
       01  WS-SEARCH           PIC X(11) VALUE '"content":"'.
       01  WS-CONTENT          PIC X(2000).
       01  WS-UNESCAPED        PIC X(2000).
       01  WS-RESP-LEN         PIC 9(4).
       01  WS-SCAN-IDX         PIC 9(4).
       01  WS-FOUND-POS        PIC 9(4).
       01  WS-CONTENT-IDX      PIC 9(4).
       01  WS-UNE-SRC-IDX      PIC 9(4).
       01  WS-UNE-DST-IDX      PIC 9(4).
       01  WS-UNE-LEN          PIC 9(4).
       01  WS-CHAR             PIC X.
       01  WS-NEXT-CHAR        PIC X.
       01  WS-PREV-CHAR        PIC X.
       01  WS-DONE             PIC X.

      *> Staging fields for CONTEXT-MGR call
       01  WS-ROLE-BUF         PIC X(20).
       01  WS-CONTENT-BUF      PIC X(2000).

       LINKAGE SECTION.
       01  LK-API-KEY          PIC X(300).
       01  LK-MODEL            PIC X(100).
       01  LK-MESSAGES-JSON    PIC X(8000).
       01  LK-MSG-COUNT        PIC 99.
       01  LK-RESPONSE         PIC X(2000).

       PROCEDURE DIVISION USING
           LK-API-KEY LK-MODEL LK-MESSAGES-JSON LK-MSG-COUNT
           LK-RESPONSE.

       MAIN-PARA.
           PERFORM BUILD-PAYLOAD
           PERFORM WRITE-PAYLOAD
           PERFORM BUILD-CURL-CMD
           PERFORM RUN-CURL
           PERFORM READ-RESPONSE
           PERFORM EXTRACT-CONTENT
           PERFORM UNESCAPE-CONTENT
           PERFORM APPEND-ASSISTANT
           MOVE WS-UNESCAPED TO LK-RESPONSE
           EXIT PROGRAM.

      *> Build: {"model":"<model>","messages":<json>}
       BUILD-PAYLOAD.
           MOVE SPACES TO WS-PAYLOAD
           STRING
               "{""model"":"""                  DELIMITED SIZE
               FUNCTION TRIM(LK-MODEL)          DELIMITED SIZE
               """,""messages"":"               DELIMITED SIZE
               FUNCTION TRIM(LK-MESSAGES-JSON)  DELIMITED SIZE
               "}"                              DELIMITED SIZE
               INTO WS-PAYLOAD.

      *> Write payload to temp file -- avoids all shell quoting issues
       WRITE-PAYLOAD.
           OPEN OUTPUT PAYLOAD-FILE
           MOVE FUNCTION TRIM(WS-PAYLOAD) TO PAYLOAD-RECORD
           WRITE PAYLOAD-RECORD
           CLOSE PAYLOAD-FILE.

      *> Build curl command using @file -- no shell quoting of JSON needed
       BUILD-CURL-CMD.
           MOVE SPACES TO WS-CURL-CMD
           STRING
               "curl -s -X POST"
               " https://openrouter.ai/api/v1/chat/completions"
               " -H 'Authorization: Bearer "
               FUNCTION TRIM(LK-API-KEY)
               "'"
               " -H 'Content-Type: application/json'"
               " -d @/tmp/cobold_payload.json"
               " > /tmp/cobold_resp.json 2>&1"
               DELIMITED SIZE
               INTO WS-CURL-CMD.

      *> Block until curl finishes
       RUN-CURL.
           CALL "SYSTEM" USING WS-CURL-CMD.

      *> Read all lines from temp file into WS-RESPONSE
       READ-RESPONSE.
           MOVE SPACES TO WS-RESPONSE
           MOVE 1 TO WS-RESP-PTR
           MOVE 'N' TO WS-EOF
           OPEN INPUT RESP-FILE
           IF WS-FILE-STATUS NOT = "00"
               MOVE "error: could not open response file"
                   TO WS-RESPONSE
               EXIT PARAGRAPH
           END-IF
           PERFORM UNTIL WS-EOF = 'Y'
               READ RESP-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       STRING
                           FUNCTION TRIM(RESP-RECORD) DELIMITED SIZE
                           INTO WS-RESPONSE WITH POINTER WS-RESP-PTR
               END-READ
           END-PERFORM
           CLOSE RESP-FILE.

      *> Find last "content":"..." value in the response JSON
       EXTRACT-CONTENT.
           MOVE SPACES TO WS-CONTENT
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RESPONSE))
               TO WS-RESP-LEN
           MOVE 0 TO WS-FOUND-POS
           PERFORM VARYING WS-SCAN-IDX FROM 1 BY 1
                   UNTIL WS-SCAN-IDX > WS-RESP-LEN - 11
               IF WS-RESPONSE(WS-SCAN-IDX:11) = WS-SEARCH
                   MOVE WS-SCAN-IDX TO WS-FOUND-POS
               END-IF
           END-PERFORM
           IF WS-FOUND-POS = 0
               MOVE FUNCTION TRIM(WS-RESPONSE) TO WS-CONTENT
               EXIT PARAGRAPH
           END-IF
           ADD 11 TO WS-FOUND-POS GIVING WS-SCAN-IDX
           MOVE 1 TO WS-CONTENT-IDX
           MOVE SPACE TO WS-PREV-CHAR
           MOVE 'N' TO WS-DONE
           PERFORM UNTIL WS-SCAN-IDX > WS-RESP-LEN
                      OR WS-DONE = 'Y'
               MOVE WS-RESPONSE(WS-SCAN-IDX:1) TO WS-CHAR
               IF WS-CHAR = '"' AND WS-PREV-CHAR NOT = '\'
                   MOVE 'Y' TO WS-DONE
               ELSE
                   MOVE WS-CHAR TO WS-CONTENT(WS-CONTENT-IDX:1)
                   ADD 1 TO WS-CONTENT-IDX
               END-IF
               MOVE WS-CHAR TO WS-PREV-CHAR
               ADD 1 TO WS-SCAN-IDX
           END-PERFORM.

      *> Decode JSON string escapes: \n -> newline, \t -> tab, \\ -> \
       UNESCAPE-CONTENT.
           MOVE SPACES TO WS-UNESCAPED
           MOVE 1 TO WS-UNE-DST-IDX
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-CONTENT))
               TO WS-UNE-LEN
           PERFORM VARYING WS-UNE-SRC-IDX FROM 1 BY 1
                   UNTIL WS-UNE-SRC-IDX > WS-UNE-LEN
               MOVE WS-CONTENT(WS-UNE-SRC-IDX:1) TO WS-CHAR
               IF WS-CHAR = '\'
                       AND WS-UNE-SRC-IDX < WS-UNE-LEN
                   ADD 1 TO WS-UNE-SRC-IDX
                   MOVE WS-CONTENT(WS-UNE-SRC-IDX:1) TO WS-NEXT-CHAR
                   EVALUATE WS-NEXT-CHAR
                       WHEN 'n'
                           MOVE X"0A" TO
                               WS-UNESCAPED(WS-UNE-DST-IDX:1)
                       WHEN 't'
                           MOVE X"09" TO
                               WS-UNESCAPED(WS-UNE-DST-IDX:1)
                       WHEN '\'
                           MOVE '\' TO
                               WS-UNESCAPED(WS-UNE-DST-IDX:1)
                       WHEN OTHER
                           MOVE WS-NEXT-CHAR TO
                               WS-UNESCAPED(WS-UNE-DST-IDX:1)
                   END-EVALUATE
               ELSE
                   MOVE WS-CHAR TO WS-UNESCAPED(WS-UNE-DST-IDX:1)
               END-IF
               ADD 1 TO WS-UNE-DST-IDX
           END-PERFORM.

      *> Append assistant reply to context
       APPEND-ASSISTANT.
           MOVE 'assistant' TO WS-ROLE-BUF
           MOVE WS-CONTENT  TO WS-CONTENT-BUF
           CALL "CONTEXT-MGR" USING
               WS-ROLE-BUF
               WS-CONTENT-BUF
               LK-MESSAGES-JSON
               LK-MSG-COUNT.
