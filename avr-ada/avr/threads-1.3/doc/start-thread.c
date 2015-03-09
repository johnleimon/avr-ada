
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr-thread.h>

// Thread stack
uint8_t fn_stack[128];
// Thread context
avr_thread_context fn_context;
// Thread code
void fn(void)
{
    uint8_t state = 0;
    for (;;) {
        if (state)
            PORTB &= ~0x02;
        else
            PORTB |= 0x02;
        state = ! state;
    }
}

int main(void)
{
    // Setup port B as all output.
    PORTB = 0xff;
    DDRB = 0xff;

    // Setup timer 2 mode.  Include reset on overflow bit.
    // Approximately 1.008 kHz for 4 MHz crystal.
    TCCR2 = _BV(WGM21) | _BV(CS21) | _BV(CS20);
    OCR2 = 62;
    TCNT2 = 0;
    TIMSK |= _BV(OCIE2);

    // Initialize avr-thread library.
    avr_thread_init();
    sei();
    // Start new thread
    avr_thread_start(&fn_context,
                     fn, fn_stack, sizeof(fn_stack));

    uint8_t state = 0;
    for (;;) {
        if (state)
            PORTB &= ~0x01;
        else
            PORTB |= 0x01;
        state = ! state;
    }
}

uint32_t switch_count = 0;

// Task switcher
void SIG_OUTPUT_COMPARE2(void) __attribute__((naked));
void SIG_OUTPUT_COMPARE2(void)
{
    sei();
    avr_thread_isr_start();
    switch_count++;
    avr_thread_isr_end();
}
