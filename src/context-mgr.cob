       IDENTIFICATION DIVISION.
       PROGRAM-ID. CONTEXT-MGR.

      *> Called with: CALL "CONTEXT-MGR"
      *>   USING BY REFERENCE CM-ROLE, CM-CONTENT, CM-JSON, CM-COUNT
      *>
      *> CM-ROLE    PIC X(20)   -- "user", "assistant", "system", "tool"
      *> CM-CONTENT PIC X(2000) -- plain text (may contain quotes)
            *> CM-JSON    PIC X(60000)
      *> CM-COUNT   PIC 99      -- turns appended so far, init to 0

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ESCAPED          PIC X(2000).
       01  WS-SRC-IDX          PIC 9(4).
       01  WS-DST-IDX          PIC 9(4).
       01  WS-SRC-LEN          PIC 9(4).
       01  WS-CHAR             PIC X.
         01  WS-JSON-LEN         PIC 9(5).
         01  WS-PTR              PIC 9(5).

       LINKAGE SECTION.
       01  CM-ROLE             PIC X(20).
       01  CM-CONTENT          PIC X(2000).
         01  CM-JSON             PIC X(60000).
       01  CM-COUNT            PIC 99.

       PROCEDURE DIVISION USING CM-ROLE CM-CONTENT CM-JSON CM-COUNT.

       MAIN-PARA.
           PERFORM ESCAPE-PARA
           PERFORM APPEND-PARA
           EXIT PROGRAM.

      *> Escape CM-CONTENT for embedding in a JSON string value.
      *> Handles: \ -> \\   " -> \"   newline -> \n
       ESCAPE-PARA.
           MOVE SPACES TO WS-ESCAPED
           MOVE 1 TO WS-DST-IDX
           MOVE FUNCTION LENGTH(FUNCTION TRIM(CM-CONTENT))
               TO WS-SRC-LEN
           PERFORM VARYING WS-SRC-IDX FROM 1 BY 1
                   UNTIL WS-SRC-IDX > WS-SRC-LEN
               MOVE CM-CONTENT(WS-SRC-IDX:1) TO WS-CHAR
               EVALUATE WS-CHAR
                   WHEN '\'
                       MOVE '\' TO WS-ESCAPED(WS-DST-IDX:1)
                       ADD 1 TO WS-DST-IDX
                       MOVE '\' TO WS-ESCAPED(WS-DST-IDX:1)
                   WHEN '"'
                       MOVE '\' TO WS-ESCAPED(WS-DST-IDX:1)
                       ADD 1 TO WS-DST-IDX
                       MOVE '"' TO WS-ESCAPED(WS-DST-IDX:1)
                   WHEN X"0A"
                       MOVE '\' TO WS-ESCAPED(WS-DST-IDX:1)
                       ADD 1 TO WS-DST-IDX
                       MOVE 'n' TO WS-ESCAPED(WS-DST-IDX:1)
                   WHEN X"0D"
                       MOVE '\' TO WS-ESCAPED(WS-DST-IDX:1)
                       ADD 1 TO WS-DST-IDX
                       MOVE 'r' TO WS-ESCAPED(WS-DST-IDX:1)
                   WHEN X"09"
                       MOVE '\' TO WS-ESCAPED(WS-DST-IDX:1)
                       ADD 1 TO WS-DST-IDX
                       MOVE 't' TO WS-ESCAPED(WS-DST-IDX:1)
                   WHEN OTHER
                       MOVE WS-CHAR TO WS-ESCAPED(WS-DST-IDX:1)
               END-EVALUATE
               ADD 1 TO WS-DST-IDX
           END-PERFORM
           MOVE WS-ESCAPED TO CM-CONTENT.

      *> Append one {"role":"...","content":"..."} object to CM-JSON
       APPEND-PARA.
           MOVE FUNCTION LENGTH(FUNCTION TRIM(CM-JSON))
               TO WS-JSON-LEN
      *>   WS-PTR = position of the closing ']' -- we overwrite it
           MOVE WS-JSON-LEN TO WS-PTR
           IF CM-COUNT > 0
               STRING ',' DELIMITED SIZE
                      INTO CM-JSON WITH POINTER WS-PTR
           END-IF
           STRING '{"role":"'               DELIMITED SIZE
                  FUNCTION TRIM(CM-ROLE)    DELIMITED SIZE
                  '","content":"'           DELIMITED SIZE
                  FUNCTION TRIM(CM-CONTENT) DELIMITED SIZE
                  '"}]'                     DELIMITED SIZE
                  INTO CM-JSON WITH POINTER WS-PTR
           ADD 1 TO CM-COUNT.
