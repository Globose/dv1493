    .data
buffer_in:      .space  64          # Allocate 64 bytes for the buffer_in
buffer_in_pos:  .byte   0           # Initialize buffer_in position to 0
buffer_out:     .space  64          # Allocate 64 bytes for the buffer_out
buffer_out_pos: .byte   0           # Initialize buffer_out position to 0
buffer_integer: .space  64          # Allocate 64 bytes for int to string

.text

/*
    inImage:
    Läser en textrad från stdin till inmatningsbuffert
 */
    .global inImage
inImage:
    leaq    buffer_in, %rdi         # Set buffer address
    movq    $64, %rsi               # Set count
    movq    stdin, %rdx             # Set file to stdin

    # Stack alignment
    mov     %rsp, %rax              # Move %rsp to %rax
    and     $0xF, %rax              # Mask with 0xF to get lower 4 bits
    subq    %rax, %rsp              # Align it to 16-byte
    pushq   %rax                    # Push aligner
    pushq   $0                      # Space push

    call    fgets                   # Call fgets(buf, count, file)
    pop     %rax                    # Pop space
    pop     %rax                    # Pop aligner
    addq    %rax, %rsp              # Reset stack
    movb    $0, buffer_in_pos       # Reset the buffer_in position
    ret

/* getInt:
    Returnerar ett tal från inbuffer
    Retur: tal (%rax)
 */
    .global getInt
getInt:
    xorq    %rax, %rax              # Set int to 0
    leaq    buffer_in, %rbx         # Load address of buffer_in
    xorq    %rcx, %rcx              # Reset %rcx
    xorq    %rdx, %rdx              # Reset %rdx
    movb    buffer_in_pos, %cl      # Load buffer_in position
    movb    (%rbx, %rcx, 1), %dl    # Load character from buffer

    # Null check
    cmpb    $0, %dl                 # Check if buffer is empty
    je      getInt_fillbuffer       # Fill buffer
    cmpb    $10, %dl                # Check if newline
    je      getInt_fillbuffer       # Fill buffer

    xorb    %r8b, %r8b              # Set isNegative to false
    cmpb    $48, %dl                # Compare the character to 0 in ascii
    jge     getInt_loop             # Int has no prefix, start loop

getInt_getPrefix:
    # Int has prefix, compare to get which prefix
    call    getInt_checkBounds      # Check bounds
    movb    (%rbx, %rcx, 1), %dl    # Load character from buffer
    cmpb    $32, %dl                # Check if it is a space
    je      getInt_prefixSpace      # Handle space
    cmpb    $43, %dl                # Check if it is a plus
    je      getInt_prefixPlus       # Handle plus
    cmpb    $45, %dl                # Check if it is a minus
    je      getInt_prefixMinus      # Handle minus
    jmp     getInt_loop             # Prefix over, start loop

getInt_loop:
    call    getInt_checkBounds      # Check bounds
    movb    (%rbx, %rcx, 1), %dl    # Load character from buffer
    subb    $48, %dl                # Subtract ascii 0 to get char as int
    cmpb    $9, %dl                 # If over 9, it is not an int
    jg      getInt_end              # If not int, return
    cmpb    $0, %dl                 # If under 0, it is not an int
    jl      getInt_end              # If not int, return
    imulq   $10, %rax               # Multiply by 10 to add next digit
    addq    %rdx, %rax              # Add next digit
    incb    %cl                     # Increment buffer position
    jmp     getInt_loop             # Check next character

getInt_checkBounds:
    cmpb    $63, %cl                # Check if buffer_in position is out of bounds
    jge     getInt_refreshBuffer    # Call inImage if it is
    ret

getInt_fillbuffer:
    call inImage                    # Fill buffer
    jmp getInt                      # Start over

getInt_refreshBuffer:
    call    inImage                 # Refresh buffer_in
    movb    buffer_in_pos, %cl      # Load new buffer_in position
    jmp     getInt_checkBounds      # Return

getInt_prefixSpace:
    incb    %cl                     # Increment buffer position
    jmp     getInt_getPrefix        # Check next position

getInt_prefixMinus:
    movb    $1, %r8b                # Set isNegative to true

getInt_prefixPlus:
    incb    %cl                     # Increment buffer position
    jmp     getInt_loop             # Start loop

getInt_negate:
    negq    %rax                    # Negate the number
    ret

getInt_end:
    movb    %cl, buffer_in_pos      # Save buffer_in position
    cmpb    $1, %r8b                # Check if the number should be negative
    je      getInt_negate           # If so, negate it
    ret

/*
    getText:
    Överför n tecken från inbuffert till minnesplats.
    Parameter 1: minnesplats dit strängen kopieras (%rdi)
    Parameter 2: n, maximalt antal tecken att läsa (%rsi)
    Retur: antal överförda tecken (%rax)
 */
    .global getText
getText:
    movq    $0, %rax                # Set %rax to 0
    leaq    buffer_in, %rbx         # Load address of buffer_in
    movq    $0, %rcx                # Reset %rcx
    movb    buffer_in_pos, %cl      # Load buffer_in position value
    movb    (%rbx, %rcx), %dl       # Load character from buffer

    cmpb    $0, %dl                 # Check if char is null
    je      getTextFillBuffer       # If buffer is empty
    cmpb    $10, %dl                # Check if char is newline
    je      getTextFillBuffer       # If buffer is newline
    movb    %dl, (%rdi,%rax)        # Write char to output

getTextLoop:
    addq    $1, %rax                # Add 1 to counter
    addq    $1, %rcx                # Add 1 to fetch position
    movb    (%rbx, %rcx), %dl       # Load character from buffer

    cmpq    %rsi, %rax              # End condition
    je getTextReturn                # Return
    cmpb    $0, %dl                 # Check if %dl is null
    je getTextReturn                # Return

    movb    %dl, (%rdi,%rax)        # Write char to output
    jmp getTextLoop                 # Repeat

getTextReturn:
    addq    %rax, buffer_in_pos     # Add to buffer_in pos
    movb    $0, (%rdi,%rax)         # Null to end
    ret

getTextFillBuffer:
    pushq   %rdi                    # Push %rdi
    call    inImage                 # Call inImage
    popq    %rdi                    # Pop %rdi
    jmp     getText                 # Go back

/*
    getChar:
    Returnerar ett tecken från inmatningsbuffertens aktuella position.
    Retur: char (%rax)
 */
    .global getChar
getChar:
    leaq    buffer_in, %rbx         # Load address of buffer_in
    movq    $0, %rcx                # Reset %rcx
    movb    buffer_in_pos, %cl      # Load value buffer_in position
    leaq    (%rbx, %rcx), %rdx      # Load adress for wanted char
    movb    (%rdx), %al             # Load character from buffer

    cmpb    $0, %al                 # Check if %al is null
    je      getCharRefill           # If buffer is empty
    cmpb    $10, %al                # Check if %al newline
    je      getCharRefill           # If buffer is empty
    addb    $1, buffer_in_pos       # Add 1 to buffer_in position
    ret

getCharRefill:
    call    inImage                 # Call inImage
    jmp     getChar                 # Jump back


/* getInPos:
    Returnerar aktuellt buffertposition för inbuffert
    Retur: index (%rax)
 */
    .global getInPos
getInPos:
    movq    buffer_in_pos, %rax     # Load buffer_in position value
    ret

/* setInPos:
    Sätter ett värde på aktuell inbuffertposition
    Parameter: position (%rdi)
 */
    .global setInPos
setInPos:
    cmpq    $0, %rdi                # Compare to 0
    jl      setInPosZero            # If less than 0
    cmpq    $63, %rdi               # Compare to 63
    jg      setInPosMax             # If greater than 63
    movb    %dil, buffer_in_pos     # Reset the buffer_in position
    ret

setInPosZero:
    movb    $0, buffer_in_pos      # Set buffer_in position to 0
    ret

setInPosMax:
    movb    $63, buffer_in_pos      # Set buffer_in position to 63
    ret


    # Output
    .global outImage
outImage:
    leaq    buffer_out, %rdi        # Set buffer address
    subq    $8, %rsp                # Stack alignment
    call    puts                    # Call puts(buf)
    addq    $8, %rsp                # Stack alignment

    movq    $0, buffer_out_pos      # Reset the buffer_out position
    ret


/* putInt:
    Lägger till ett tal n som sträng i utbufferten
    Parameter: tal n (%rdi)
 */
    .global putInt
putInt:
    movq    $10, %rsi               # Set divisor 10 to %rsi
    movq    $0, %rcx                # Set %rcx to 0
    movq    %rdi, %rax              # Assign number to %rax
    leaq    buffer_integer, %rbx    # Set buffer address
    movq    $63, %rdi               # Set buffer position
    cmpq    $0, %rax                # Less than 0 check
    jge     putIntDivide            # Positive or 0
    movq    $45, (%rbx,%rcx,1)      # Save - to buffer start
    addq    $1, %rcx                # Increase buffer position
    neg     %rax                    # Flip negative to positive

putIntDivide:
    xor     %rdx, %rdx              # Clear %rdx
    div     %rsi                    # result: %rax, remainder: %rdx
    addq    $48, %rdx               # Convert remainder to string
    movb    %dl, (%rbx,%rdi,1)      # Save remainder to buffer end
    subq    $1, %rdi                # Subtract buffer position
    cmpq    $0, %rax                # Compare remainder to 0
    jne     putIntDivide            # Restart loop

    addq    $1, %rdi

putIntReverse:
    movb    (%rbx, %rdi, 1), %al    # Load character buffer
    movq    %rax, (%rbx,%rcx,1)     # Save char to buffer start
    addq    $1, %rcx
    addq    $1, %rdi
    movb    $0, (%rbx,%rcx,1)       # Add null to next position
    cmpq    $64, %rdi               # End of buffer
    je putIntEnd
    jmp putIntReverse

putIntEnd:
    leaq    buffer_integer, %rdi    # Set %rdi to integer buffer
    jmp     putText

/* putText:
    Lägger texten från buf till utbuffert
    Parameter: adress till buf (%rdi)
 */
    .global putText
putText:
    movq    %rdi, %rcx              # Load address of string
    movq    $0, %rdx                # Set string position to 0

putText_loop:
    movb    (%rcx, %rdx, 1), %dil   # Load character from string
    cmpb    $0, %dil                # Check if character is null
    je      putText_end             # End loop if it is null

    pushq   %rcx
    pushq   %rdx
    subq    $8, %rsp                # Stack alignment
    call    putChar                 # Call putChar to write the character to the buffer
    addq    $8, %rsp                # Stack alignment
    popq    %rdx
    popq    %rcx

    incq    %rdx                    # Increment string position
    jmp     putText_loop            # Loop

putText_end:
    ret

/*
    putChar
    Lägger till char c i utbufferten
    Parameter: c (%rdi)
 */
    .global putChar
putChar:
    cmpb    $63, buffer_out_pos     # Check if buffer_out is full
    jge     flush_buffer

putChar_end:
    leaq    buffer_out, %rax        # Load address of buffer_out
    movq    $0, %rbx                # Reset %rbx
    movb    buffer_out_pos, %bl     # Load buffer_out position
    movb    %dil, (%rax, %rbx, 1)   # Add the character to the buffer_out
    addq    $1, %rbx                # Add 1 to %rbx
    movb    $0, (%rax, %rbx, 1)     # Add null character to next pos
    subq    $1, %rbx                # Sub 1 from %rbx
    incb    %bl                     # Increment the buffer_out position
    movb    %bl, buffer_out_pos     # Save buffer_out position
    ret

flush_buffer:
    pushq   %rdi
    call    outImage                # Call outImage to print the buffer
    popq    %rdi
    jmp     putChar_end             # Jump back to the end of putChar

    .global getOutPos
getOutPos:
    movq    buffer_out_pos, %rax    # Moves the buffer_out position to %rax for return
    ret

    .global setOutPos
setOutPos:
    cmpb    $0, %dil                # Checks if index is less than 0
    jl      setMin                  # If so, jump to setMin
    cmpb    $64, %dil               # Checks if index is larger than 63
    jge     setMax                  # If so, jump to setMax
    jmp     setIndex                # If not, jump to setIndex

setMin:
    movb    $0, %dil                # Set index to 0
    jmp     setIndex                # Jump to setIndex

setMax:
    movb    $63, %dil               # Set index to 63

setIndex:
    movb    %dil, buffer_out_pos    # Set buffer_out position
    ret

