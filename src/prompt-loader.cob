       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROMPT-LOADER.

      *> CALL "PROMPT-LOADER" USING BY REFERENCE PL-CONTENT PL-STATUS
      *>
      *> PL-CONTENT  PIC X(2000) -- raw prompt text on return
      *> PL-STATUS   PIC X       -- 'Y' = loaded OK, 'N' = file not found
      *>
      *> Caller is responsible for JSON-escaping (e.g. via CONTEXT-MGR).

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PROMPT-FILE
               ASSIGN TO 'prompts/system-prompt.txt'
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  PROMPT-FILE.
       01  PROMPT-RECORD       PIC X(500).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS      PIC XX.
       01  WS-EOF              PIC X.
       01  WS-PTR              PIC 9(4).

       LINKAGE SECTION.
       01  PL-CONTENT          PIC X(2000).
       01  PL-STATUS           PIC X.

       PROCEDURE DIVISION USING PL-CONTENT PL-STATUS.

       MAIN-PARA.
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
