*-----------------------------------------------------------
* Title      : I/O Part
* Written by : Kevin Fong
* Date       :
* Description: The I/O part of the CSS422 Project
*-----------------------------------------------------------

START:      ORG    $1000

DEBUG       move.l  #$00004000, startAddr
            move.l  #$00005000, endAddr
            bra     readFile

            move.b  #14,d0      ; Display welcome
            lea     welcomeMsg,a1
            trap    #15
    
startPrompt move.b  #14,d0      ; Display prompt for startAddr
            lea     startAddrMsg,a1
            trap    #15
            movea   #0, a1      ; clear a1 for input
    
getStartAddr move.b #2,d0       ; user input, store in (a1), length in D1
            trap    #15
    
            jsr     parse_input ; convert input
            
            move.l  #0, d3      ;check lower bound
            add.l   #startMin, d3
            cmp.l   d3, d5
            blt     tooLow
            
            move.l  #0, d3      ; check upper bound
            add.l   #endMax, d3
            cmp.l   d3, d5
            bgt     tooHigh
            
            move.l  #0, d3      ; check if odd
            move.l  d5, d3
            asr     #1, d3
            bcs     oddAddr
            
            move.l  d5, startAddr   ; store startAddr
            
endPrompt   move.b  #14,d0      ; Display prompt for endAddr
            lea     endAddrMsg,a1
            trap    #15
            movea   #0, a1      ; clear a1 for input
    
getEndAddr  move.b #2,d0       ; user input, store in (a1), length in D1
            trap    #15
    
            jsr     parse_input ; convert input
            
            move.l  #0, d3      ;check lower bound
            add.l   startAddr, d3
            cmp.l   d3, d5
            blt     tooLow
            
            move.l  #0, d3      ; check upper bound
            add.l   #endMax, d3
            cmp.l   d3, d5
            bgt     tooHigh
            
            move.l  #0, d3      ; check if odd
            move.l  d5, d3
            asr     #1, d3
            bcs     oddAddr
            
            move.l  d5, endAddr     ; store endAddr
            
readFile    lea     filename, a1    ; load file name
            move    #51, d0
            trap    #15
            
            move.l  endAddr, d2     
            sub.l   startAddr, d2   ; store length in d2   
            move.l  d2, filesize    ; get length from start to end
            
            lea     buffer, a1      ; create storage buffer
            move    #53, d0
            trap    #15
            
convertFile move.l  startAddr, a2
            jsr     parse_file
            
startDecode move.l  startAddr, a4   ; load starting location into a4
            bra     nextCode        
            
decodeLoop  bra     FINISH          

nextCode    jsr     checkEnd
            clr.l   d5
            lea     goodBuffer, a2  ;reset a2
            move.w  a4, a0          ; store current addr into a0
            
            move.l  #2, d7
            move.l  a0, d3
            move.l  d3, d6
            lea     goodBuffer,A2
            jsr     printData
            
            move.b  #' ', (a2)+     ; print spaces
            move.b  #' ', (a2)+
            move.b  #' ', (a2)+
            move.b  #' ', (a2)+
            
            clr.l   d6      
            clr.l   d3
            
            move.w  (a4)+, d6       ; load new data
            move.w  d6, d3          ; copy new data
            lsr.w   #8, d3          ; shift new data
            
            bra     decodeLoop  

*-----------------------------------------------------------
* Print Data
*-----------------------------------------------------------            
printData   cmp.w   #2, d7      ; check if long
            bne     printWord   
            swap    d3          ; if long swap data to print first word
            swap    d6          
            jsr     printWord   ; print word
            
            swap    d6          ; swap back
            move.l  d6, d3      ; move data back
 
printWord   lsr.w   #8, d3      ; get first char
            lsr.w   #4, d3
            mulu.w  #8, d3      ; ready jump table
            lea     char_table, a6 ; load jump table
            jsr     (a6,d3)     ; print first char
            
            move.w  d6, d3      ; copy data
            lsl.w   #4, d3      ; remove first char
            lsr.w   #8, d3      ; get second char
            lsr.w   #4, d3
            mulu.w  #8, d3      ; ready jump table
            lea     char_table, a6  ;load jump table
            jsr     (a6, d3)    ; print second char
            
            move.w  d6, d3      ; copy data
            lsl.w   #8, d3      ; remove second char
            lsr.w   #8, d3      ; get third char
            lsr.w   #4, d3
            mulu.w  #8, d3      ; ready jump table
            lea     char_table, a6  ;load jump table
            jsr     (a6, d3)    ; print third char
            
            move.w  d6, d3      ; copy data
            lsl.w   #8, d3      ; remove third char
            lsl.w   #4, d3      
            lsr.w   #8, d3      ; get fourth char
            lsr.w   #4, d3
            mulu.w  #8, d3      ; ready jump table
            lea     char_table, a6  ;load jump table
            jsr     (a6, d3)    ; print fourth char
            
            addi.b  #4, d5      ; add 4 to counter or output
            rts
*-----------------------------------------------------------
* Check for end address
*-----------------------------------------------------------
checkEnd    move.l  endAddr, d1
            move.l  a4, d5
            cmp.l   d5, d1      ;compare the current and end addr
            ble     FINISH      ; if reached end, branch to end display
            rts     
             
*-----------------------------------------------------------
* Parse File
*-----------------------------------------------------------
parse_file  move.l  #0, d5      ; clear for word storage
            move.l  #0, d3      ; clear for counter
            move.l  #0, d4
             
parse_loop1 cmp.b   #4, d4      ; check for word length
            beq     storeWord
            add.b   #1, d4
            move.b  (a1)+, d2   ; move char to d2 and prep next char
            cmp.b   #$FF, d2     ; check if end
            beq     parse_finish1           

checkBlank  cmp.b   #48, d2     ; check if char is less than '0', ie space, new line or carriage return
            blt     parse_file  ; if so, ignore
            
checkNum1   cmp.b   #57, d2     ; check if char is less than/equal to '9'
            ble     convertNum1
            
checkChar1  cmp.b   #70, d2    ; check if char is less than/equal to 'F'
            ble     convertChar1
            
checkLowerChar1 cmp.b   #102, d2    ; check if char is less than/equal to 'f'
            ble     convertLowerChar1

convertNum1 subi.b  #48, d2     ; convert to hex by subtracting 48
            bra     storeChar1

convertChar1 subi.b  #55, d2     ; convert to hex by subtracting 55
            bra     storeChar1  

convertLowerChar1 subi.b  #87, d2     ; convert to hex by subtracting 87
            bra     storeChar1

storeChar1  asl.l   #4, d5   ; shift hex digit in storage
            add.b   d2, d5   ; move converted char to storage
            bra     parse_loop1      ; loop again
            
storeWord   move.w  d5, (a2)+
            bra     parse_file
            
            
parse_finish1 rts                      
            
*-----------------------------------------------------------
* Parse Address
*-----------------------------------------------------------

parse_input cmp.b   #$0, d1  ;check if any input is given 
            beq     errNoInput
            cmpi    #$8, d1     ; check if over 8 characters given
            bgt     errInvalidInput
            clr     d5          ; clear d5 to store converted address
            bra     parse_loop
            
parse_loop  move.b  (a1)+, d2   ; move char to d2 and prep next char
            cmp.b   #$0, d2     ; check if null
            beq     parse_finish
            bra     checkNum            
            
checkNum    cmp.b   #48, d2     ; check if char is less than '0'
            blt     errInvalidChar
            cmp.b   #57, d2     ; check if char is less than/equal to '9'
            ble     convertNum
            
checkChar   cmp.b   #65, d2     ; check if char is less than 'A'
            blt     errInvalidChar
            cmp.b   #70, d2    ; check if char is less than/equal to 'F'
            ble     convertChar
            
checkLowerChar cmp.b   #97, d2     ; check if char is less than 'a'
            blt     errInvalidChar
            cmp.b   #102, d2    ; check if char is less than/equal to 'f'
            ble     convertLowerChar
            
            bra     errInvalidChar  ; if made to this point, char is invalid

convertNum  subi.b  #48, d2     ; convert to hex by subtracting 48
            bra     storeChar 

convertChar subi.b  #55, d2     ; convert to hex by subtracting 55
            bra     storeChar  

convertLowerChar subi.b  #87, d2     ; convert to hex by subtracting 87
            bra     storeChar

storeChar   asl.l   #4, d5   ; shift hex digit in storage
            add.b   d2, d5   ; move converted char to storage
            bra     parse_loop      ; loop again
            
parse_finish rts
     
*-----------------------------------------------------------
*Error Messages
*-----------------------------------------------------------
errNoInput  move.b  #14,d0      ; Display no input message
            lea     errNoInputMsg,a1
            trap    #15
            jmp     startPrompt
            
errInvalidInput  move.b  #14,d0      ; Display invalid input message
            lea     errInvalidMsg,a1
            trap    #15
            jmp     startPrompt

errInvalidChar    move.b  #14,d0      ; Display invalid input message
            lea     errInvalidCharMsg,a1
            trap    #15
            jmp     startPrompt

tooLow      move.b  #14, d0
            lea     tooLowMsg,a1
            trap    #15
            jmp     startPrompt
            
tooHigh     move.b  #14, d0
            lea     tooHighMsg,a1
            trap    #15
            jmp     startPrompt
            
oddAddr     move.b  #14, d0
            lea     oddAddrMsg,a1
            trap    #15
            jmp     startPrompt
            
*-----------------------------------------------------------
*Jump Table for chars
*-----------------------------------------------------------
char_table  jmp     char0000    ;print 0
            rts
            jmp     char0001    ;print 1
            rts
            jmp     char0010    ;print 2
            rts
            jmp     char0011    ;print 3
            rts
            jmp     char0100    ;print 4
            rts
            jmp     char0101    ;print 5
            rts
            jmp     char0110    ;print 6
            rts
            jmp     char0111    ;print 7
            rts
            jmp     char1000    ;print 8
            rts
            jmp     char1001    ;print 9
            rts
            jmp     char1010    ;print A
            rts
            jmp     char1011    ;print B
            rts
            jmp     char1100    ;print C
            rts
            jmp     char1101    ;print D
            rts
            jmp     char1110    ;print E
            rts
            jmp     char1111    ;print F
            rts
            
char0000    move.b  #'0', (a2)+
            rts
char0001    move.b  #'1', (a2)+
            rts
char0010    move.b  #'2', (a2)+
            rts
char0011    move.b  #'3', (a2)+
            rts
char0100    move.b  #'4', (a2)+
            rts
char0101    move.b  #'5', (a2)+
            rts
char0110    move.b  #'6', (a2)+
            rts
char0111    move.b  #'7', (a2)+
            rts
char1000    move.b  #'8', (a2)+
            rts
char1001    move.b  #'9', (a2)+
            rts
char1010    move.b  #'A', (a2)+
            rts
char1011    move.b  #'B', (a2)+
            rts
char1100    move.b  #'C', (a2)+
            rts
char1101    move.b  #'D', (a2)+
            rts
char1110    move.b  #'E', (a2)+
            rts
char1111    move.b  #'F', (a2)+
            rts

*-----------------------------------------------------------            
FINISH      move.b  #14,d0      ; Display prompt for end
            lea     endMsg,a1
            trap    #15
    SIMHALT             ; halt simulator

* Put variables and constants here
CR      EQU     $0D
LF      EQU     $0A



currentLoc      dc.l    1

curOpcode       dc.w    1

memory          dc.l    1
opcode          dc.w    1
operand         dc.w    1

welcomeMsg      dc.b    'Welcome to the 68k Disassembler.',CR,LF, 0
startAddrMsg    dc.b    'Please enter a starting address from $00004000 and $00FFFE00: ',0 
endAddrMsg      dc.b    'Please enter an ending address: ',0
endMsg          dc.b    'Thank you for disassembling.',0  

errNoInputMsg   dc.b    CR,LF,'Error: Please enter an address', CR,LF, 0
errInvalidMsg   dc.b    CR,LF,'Error: Invalid address', CR, LF, 0
errInvalidCharMsg   dc.b    CR,LF,'Error: Invalid char given. Valid chars are 0-9, A-F, a-f', CR, LF, 0
tooLowMsg       dc.b    CR,LF,'Error: Given address is too low', CR, LF, 0
tooHighMsg      dc.b    CR,LF,'Error: Given address is too high', CR, LF, 0
oddAddrMsg      dc.b    CR,LF,'Error: Address cannot be odd', CR, LF, 0
boundsMsg       dc.b    CR,LF,'Error: End address is lower than start address', CR, LF, 0
    
startAddr       dc.l    1
endAddr         dc.l    1
userInput       dc.l    1

startMin        EQU     $00004000
endMax          EQU     $00FFFE00

goodBuffer      dc.b    30

filename        dc.b    'TEST0.txt', 0
filesize        dc.l    1
buffer          ds.b    100


    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
