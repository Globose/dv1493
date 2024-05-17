    .data
buffer_in:      .space  64          # Allocate 64 bytes for the buffer_in
buffer_in_pos:  .byte   0           # Initialize buffer_in position to 0
buffer_out:     .space  64          # Allocate 64 bytes for the buffer_out
buffer_out_pos: .byte   0           # Initialize buffer_out position to 0

    .text
    # Input
    .global inImage
inImage:
    leaq    buffer_in, %rdi         # Set buffer address
    movq    $64, %rsi               # Set count
    movq    stdin, %rdx             # Set file to stdin
    subq    $8, %rsp                # Stack alignment
    call    fgets                   # Call fgets(buf, count, file)
    addq    $8, %rsp                # Stack alignment
    movb    $0, buffer_in_pos       # Reset the buffer_in position
    leaq    buffer_in, %rdi         # Set buffer address
    movb    $0, 63(%rdi)            # Set null at end
    ret

    .global getInt
getInt:
    xorq    %rax, %rax              # Set int to 0
    leaq    buffer_in, %rbx         # Load address of buffer_in
    xorq    %rcx, %rcx              # Reset %rcx
    xorq    %rdx, %rdx              # Reset %rdx
    movb    buffer_in_pos, %cl      # Load buffer_in position
    movb    (%rbx, %rcx, 1), %dl    # Load character from buffer
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
    movq    buffer_in_pos, %rcx     # Load buffer_in position value
    leaq    (%rbx, %rcx), %rdx      # Load adress for first char
    movb    (%rdx), %dl             # Load character from buffer

    cmpb    $0, %dl                 # Check if char is null
    je      getTextReturnOne        # If buffer is empty 
    cmpb    $10, %dl                # Check if char is newline
    je      getTextReturnOne        # If buffer is empty 
    movb    %dl, (%rdi,%rcx)        # Write char to output

getTextLoop:
    addq    $1, %rax                # Add 1 to counter
    addq    $1, %rcx                # Add 1 to fetch position
    leaq    (%rbx, %rcx), %rdx      # Load adress for char
    movb    (%rdx), %dl             # Load character from buffer

    cmpq    %rsi, %rax              # End condition
    je getTextReturn                # Return
    cmpb    $0, %dl                 # Check if %dl is null
    je getTextReturn                # Return
    cmpb    $10, %dl                # Check if %dl is \n
    je getTextReturn                # Return

    movb    %dl, (%rdi,%rcx)        # Write char to output
    jmp getTextLoop                 # Repeat

getTextReturn:
    ret

getTextReturnOne:
    pushq   %rdi                    # Push %rdi
    call    getChar                 # Refill buffer and get a char
    popq    %rdi                    # Pop %rdi
    movb    %al, (%rdi)             # Write char to output
    movq    $1, %rax                # Set %rax to 1
    ret

/*
    getChar:
    Returnerar ett tecken från inmatningsbuffertens aktuella position.
    Retur: char (%rax)
 */
    .global getChar
getChar:
    leaq    buffer_in, %rbx         # Load address of buffer_in
    movq    buffer_in_pos, %rcx     # Load value buffer_in position
    leaq    (%rbx, %rcx), %rdx      # Load adress for wanted char
    movb    (%rdx), %al             # Load character from buffer
    cmpb    $10, %al                # Check that %al is not newline
    je      getCharRefill           # If buffer is empty 
    cmpb    $0, %al                 # Check that %al is not null
    je      getCharRefill           # If buffer is empty 
    addb    $1, buffer_in_pos       # Add 1 to buffer_in position
    ret

getCharRefill:
    call    inImage                 # Call inImage
    jmp     getChar                 # Jump back

// getInPos:
//     ret

// setInPos:
//     ret

    # Output
    .global outImage
outImage:
    leaq    buffer_out, %rdi        # Set buffer address
    subq    $8, %rsp                # Stack alignment
    call    puts                    # Call puts(buf)
    addq    $8, %rsp                # Stack alignment

    movq    $0, buffer_out_pos      # Reset the buffer_out position
    ret

    .global putInt
putInt:
    ret

/* putText:
    Lägger texten från buf [position] till utbuffert
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

    .global putChar
putChar:
    # Check if buffer_out is full
    cmpb    $63, buffer_out_pos
    movb    %dil, %cl
    jge     flush_buffer

putChar_end:
    leaq    buffer_out, %rax        # Load address of buffer_out
    movq    buffer_out_pos, %rbx    # Load buffer_out position

    movb    %cl, (%rax, %rbx, 1)    # Add the character to the buffer_out
    incq    %rbx                    # Increment the buffer_out position
    movq    %rbx, buffer_out_pos    # Save buffer_out position
    ret

flush_buffer:
    pushq   %rcx
    call    outImage                # Call outImage to print the buffer
    popq    %rcx
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


.data
textMessage: .asciz "Hello world this is a message!\n"
