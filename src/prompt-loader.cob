       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROMPT-LOADER.

      *> CALL "PROMPT-LOADER" USING BY REFERENCE PL-CONTENT PL-STATUS
      *>
      *> PL-CONTENT  PIC X(2000) -- raw prompt text on return
      *> PL-STATUS   PIC X       -- 'Y' = loaded OK, 'N' = file not found
      *>
      *> Resolves prompts/system-prompt.txt relative to the executable,
      *> matching ENV-READER behaviour. Caller handles JSON-escaping.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PROMPT-FILE
               ASSIGN TO DYNAMIC WS-PROMPT-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  PROMPT-FILE.
       01  PROMPT-RECORD       PIC X(500).

       WORKING-STORAGE SECTION.
       01  WS-PROMPT-PATH      PIC X(500).
       01  WS-EXE-PATH         PIC X(500).
       01  WS-PATH-LEN         PIC 9(4).
       01  WS-SLASH-POS        PIC 9(4).
       01  WS-FILE-STATUS      PIC XX.
       01  WS-EOF              PIC X.
       01  WS-PTR              PIC 9(4).

       LINKAGE SECTION.
       01  PL-CONTENT          PIC X(2000).
       01  PL-STATUS           PIC X.

       PROCEDURE DIVISION USING PL-CONTENT PL-STATUS.

       MAIN-PARA.
           PERFORM GET-PROMPT-PATH
           MOVE SPACES TO PL-CONTENT
           MOVE 'N'    TO WS-EOF
           MOVE 1      TO WS-PTR

           OPEN INPUT PROMPT-FILE
           IF WS-FILE-STATUS NOT = "00"
               MOVE 'N' TO PL-STATUS
               EXIT PROGRAM
           END-IF

           PERFORM UNTIL WS-EOF = 'Y'
               READ PROMPT-FILE
                   AT END
                       MOVE 'Y' TO WS-EOF
                   NOT AT END
                       STRING FUNCTION TRIM(PROMPT-RECORD) ' '
                           DELIMITED SIZE
                           INTO PL-CONTENT WITH POINTER WS-PTR
               END-READ
           END-PERFORM
           CLOSE PROMPT-FILE

           MOVE 'Y' TO PL-STATUS
           EXIT PROGRAM.

      *> Build path: <exe-dir>/prompts/system-prompt.txt
       GET-PROMPT-PATH.
           ACCEPT WS-EXE-PATH FROM ENVIRONMENT "_"
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-EXE-PATH, TRAILING))
               TO WS-PATH-LEN
           MOVE 0 TO WS-SLASH-POS
           INSPECT FUNCTION REVERSE(
               FUNCTION TRIM(WS-EXE-PATH, TRAILING))
               TALLYING WS-SLASH-POS FOR CHARACTERS BEFORE '/'
           IF WS-SLASH-POS = WS-PATH-LEN
               MOVE "./prompts/system-prompt.txt"
                   TO WS-PROMPT-PATH
           ELSE
               STRING
                   WS-EXE-PATH(1:WS-PATH-LEN - WS-SLASH-POS)
                   "prompts/system-prompt.txt"
                   DELIMITED SIZE INTO WS-PROMPT-PATH
           END-IF.
