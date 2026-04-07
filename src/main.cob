       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOLD-CLI.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-API-KEY          PIC X(300).
       01  WS-MODEL            PIC X(100).
       01  WS-USER-INPUT       PIC X(1000).
       01  WS-RUNNING          PIC X VALUE 'Y'.
       01  WS-AI-RESPONSE      PIC X(2000).

      * System prompt
       01  WS-PROMPT-CONTENT   PIC X(2000).
       01  WS-PROMPT-STATUS    PIC X.

      * Conversation context
        01  WS-MESSAGES-JSON    PIC X(60000) VALUE '[]'.
       01  WS-MSG-COUNT        PIC 99      VALUE 0.
       01  WS-MSG-ROLE         PIC X(20).
       01  WS-MSG-CONTENT      PIC X(2000).
        01  WS-CONTEXT-SIZE     PIC 9(5).

      * ANSI escape sequences (ESC [ ... m)
       01  CLR                 PIC X(4) VALUE X"1B5B306D".
       01  BOLD                PIC X(4) VALUE X"1B5B316D".
       01  DIM                 PIC X(4) VALUE X"1B5B326D".
       01  BLUE                PIC X(5) VALUE X"1B5B33346D".
       01  GREEN               PIC X(5) VALUE X"1B5B33326D".

       PROCEDURE DIVISION.

       MAIN-PARA.
           CALL "ENV-READER" USING WS-API-KEY, WS-MODEL

           CALL "PROMPT-LOADER" USING WS-PROMPT-CONTENT
               WS-PROMPT-STATUS
           IF WS-PROMPT-STATUS = 'Y'
               MOVE 'system'          TO WS-MSG-ROLE
               MOVE WS-PROMPT-CONTENT TO WS-MSG-CONTENT
               CALL "CONTEXT-MGR" USING
                   WS-MSG-ROLE
                   WS-MSG-CONTENT
                   WS-MESSAGES-JSON
                   WS-MSG-COUNT
           END-IF

           DISPLAY BOLD "=========================================" CLR
           DISPLAY BOLD "   cobold-cli  --  AI agent in COBOL    " CLR
           DISPLAY BOLD "=========================================" CLR
           DISPLAY DIM "Model: " FUNCTION TRIM(WS-MODEL) CLR
           DISPLAY DIM "Type /q to quit" CLR
           DISPLAY " "

           PERFORM UNTIL WS-RUNNING = 'N'
               DISPLAY BLUE "you @> " CLR WITH NO ADVANCING
               ACCEPT WS-USER-INPUT

               IF FUNCTION TRIM(WS-USER-INPUT) = '/q'
                   MOVE 'N' TO WS-RUNNING
               ELSE
                   MOVE 'user'        TO WS-MSG-ROLE
                   MOVE WS-USER-INPUT TO WS-MSG-CONTENT
                   CALL "CONTEXT-MGR" USING
                       WS-MSG-ROLE
                       WS-MSG-CONTENT
                       WS-MESSAGES-JSON
                       WS-MSG-COUNT

                   CALL "AI-CALLER" USING
                       WS-API-KEY
                       WS-MODEL
                       WS-MESSAGES-JSON
                       WS-MSG-COUNT
                       WS-AI-RESPONSE

                   MOVE FUNCTION LENGTH(
                       FUNCTION TRIM(WS-MESSAGES-JSON))
                       TO WS-CONTEXT-SIZE

                   DISPLAY " "
                   DISPLAY GREEN "ai @> " CLR
                       FUNCTION TRIM(WS-AI-RESPONSE)
                   DISPLAY DIM "context @> "
                       FUNCTION TRIM(WS-CONTEXT-SIZE)
                       "/60000 chars used" CLR
                   DISPLAY " "
               END-IF
           END-PERFORM

           STOP RUN.
