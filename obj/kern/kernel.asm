
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 c0 72 01 00    	add    $0x172c0,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f0100058:	c7 c0 c0 96 11 f0    	mov    $0xf01196c0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 4e 3e 00 00       	call   f0103eb7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 36 05 00 00       	call   f01005a4 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 f4 cf fe ff    	lea    -0x1300c(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 ec 31 00 00       	call   f010326e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 d9 13 00 00       	call   f0101460 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 3b 08 00 00       	call   f01008cf <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 65 72 01 00    	add    $0x17265,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 c4 96 11 f0    	mov    $0xf01196c4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 0a 08 00 00       	call   f01008cf <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 0f d0 fe ff    	lea    -0x12ff1(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 88 31 00 00       	call   f010326e <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 47 31 00 00       	call   f0103237 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 92 df fe ff    	lea    -0x1206e(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 70 31 00 00       	call   f010326e <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 ff 71 01 00    	add    $0x171ff,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 27 d0 fe ff    	lea    -0x12fd9(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 43 31 00 00       	call   f010326e <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 00 31 00 00       	call   f0103237 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 92 df fe ff    	lea    -0x1206e(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 29 31 00 00       	call   f010326e <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100156:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010015b:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 0b                	je     f010016b <serial_proc_data+0x18>
f0100160:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100165:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100166:	0f b6 c0             	movzbl %al,%eax
}
f0100169:	5d                   	pop    %ebp
f010016a:	c3                   	ret    
		return -1;
f010016b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100170:	eb f7                	jmp    f0100169 <serial_proc_data+0x16>

f0100172 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100172:	55                   	push   %ebp
f0100173:	89 e5                	mov    %esp,%ebp
f0100175:	56                   	push   %esi
f0100176:	53                   	push   %ebx
f0100177:	e8 d3 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010017c:	81 c3 90 71 01 00    	add    $0x17190,%ebx
f0100182:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100184:	ff d6                	call   *%esi
f0100186:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100189:	74 2e                	je     f01001b9 <cons_intr+0x47>
		if (c == 0)
f010018b:	85 c0                	test   %eax,%eax
f010018d:	74 f5                	je     f0100184 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018f:	8b 8b 78 1f 00 00    	mov    0x1f78(%ebx),%ecx
f0100195:	8d 51 01             	lea    0x1(%ecx),%edx
f0100198:	89 93 78 1f 00 00    	mov    %edx,0x1f78(%ebx)
f010019e:	88 84 0b 74 1d 00 00 	mov    %al,0x1d74(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001ab:	75 d7                	jne    f0100184 <cons_intr+0x12>
			cons.wpos = 0;
f01001ad:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f01001b4:	00 00 00 
f01001b7:	eb cb                	jmp    f0100184 <cons_intr+0x12>
	}
}
f01001b9:	5b                   	pop    %ebx
f01001ba:	5e                   	pop    %esi
f01001bb:	5d                   	pop    %ebp
f01001bc:	c3                   	ret    

f01001bd <kbd_proc_data>:
{
f01001bd:	55                   	push   %ebp
f01001be:	89 e5                	mov    %esp,%ebp
f01001c0:	56                   	push   %esi
f01001c1:	53                   	push   %ebx
f01001c2:	e8 88 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001c7:	81 c3 45 71 01 00    	add    $0x17145,%ebx
f01001cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01001d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001d3:	a8 01                	test   $0x1,%al
f01001d5:	0f 84 06 01 00 00    	je     f01002e1 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001db:	a8 20                	test   $0x20,%al
f01001dd:	0f 85 05 01 00 00    	jne    f01002e8 <kbd_proc_data+0x12b>
f01001e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01001e8:	ec                   	in     (%dx),%al
f01001e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001eb:	3c e0                	cmp    $0xe0,%al
f01001ed:	0f 84 93 00 00 00    	je     f0100286 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	0f 88 a0 00 00 00    	js     f010029b <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f01001fb:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f0100201:	f6 c1 40             	test   $0x40,%cl
f0100204:	74 0e                	je     f0100214 <kbd_proc_data+0x57>
		data |= 0x80;
f0100206:	83 c8 80             	or     $0xffffff80,%eax
f0100209:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010020b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010020e:	89 8b 54 1d 00 00    	mov    %ecx,0x1d54(%ebx)
	shift |= shiftcode[data];
f0100214:	0f b6 d2             	movzbl %dl,%edx
f0100217:	0f b6 84 13 74 d1 fe 	movzbl -0x12e8c(%ebx,%edx,1),%eax
f010021e:	ff 
f010021f:	0b 83 54 1d 00 00    	or     0x1d54(%ebx),%eax
	shift ^= togglecode[data];
f0100225:	0f b6 8c 13 74 d0 fe 	movzbl -0x12f8c(%ebx,%edx,1),%ecx
f010022c:	ff 
f010022d:	31 c8                	xor    %ecx,%eax
f010022f:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100235:	89 c1                	mov    %eax,%ecx
f0100237:	83 e1 03             	and    $0x3,%ecx
f010023a:	8b 8c 8b f4 1c 00 00 	mov    0x1cf4(%ebx,%ecx,4),%ecx
f0100241:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100245:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100248:	a8 08                	test   $0x8,%al
f010024a:	74 0d                	je     f0100259 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f010024c:	89 f2                	mov    %esi,%edx
f010024e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100251:	83 f9 19             	cmp    $0x19,%ecx
f0100254:	77 7a                	ja     f01002d0 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f0100256:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100259:	f7 d0                	not    %eax
f010025b:	a8 06                	test   $0x6,%al
f010025d:	75 33                	jne    f0100292 <kbd_proc_data+0xd5>
f010025f:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100265:	75 2b                	jne    f0100292 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100267:	83 ec 0c             	sub    $0xc,%esp
f010026a:	8d 83 41 d0 fe ff    	lea    -0x12fbf(%ebx),%eax
f0100270:	50                   	push   %eax
f0100271:	e8 f8 2f 00 00       	call   f010326e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100276:	b8 03 00 00 00       	mov    $0x3,%eax
f010027b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100280:	ee                   	out    %al,(%dx)
f0100281:	83 c4 10             	add    $0x10,%esp
f0100284:	eb 0c                	jmp    f0100292 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100286:	83 8b 54 1d 00 00 40 	orl    $0x40,0x1d54(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100292:	89 f0                	mov    %esi,%eax
f0100294:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100297:	5b                   	pop    %ebx
f0100298:	5e                   	pop    %esi
f0100299:	5d                   	pop    %ebp
f010029a:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010029b:	8b 8b 54 1d 00 00    	mov    0x1d54(%ebx),%ecx
f01002a1:	89 ce                	mov    %ecx,%esi
f01002a3:	83 e6 40             	and    $0x40,%esi
f01002a6:	83 e0 7f             	and    $0x7f,%eax
f01002a9:	85 f6                	test   %esi,%esi
f01002ab:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002ae:	0f b6 d2             	movzbl %dl,%edx
f01002b1:	0f b6 84 13 74 d1 fe 	movzbl -0x12e8c(%ebx,%edx,1),%eax
f01002b8:	ff 
f01002b9:	83 c8 40             	or     $0x40,%eax
f01002bc:	0f b6 c0             	movzbl %al,%eax
f01002bf:	f7 d0                	not    %eax
f01002c1:	21 c8                	and    %ecx,%eax
f01002c3:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
		return 0;
f01002c9:	be 00 00 00 00       	mov    $0x0,%esi
f01002ce:	eb c2                	jmp    f0100292 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002d0:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002d3:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002d6:	83 fa 1a             	cmp    $0x1a,%edx
f01002d9:	0f 42 f1             	cmovb  %ecx,%esi
f01002dc:	e9 78 ff ff ff       	jmp    f0100259 <kbd_proc_data+0x9c>
		return -1;
f01002e1:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002e6:	eb aa                	jmp    f0100292 <kbd_proc_data+0xd5>
		return -1;
f01002e8:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002ed:	eb a3                	jmp    f0100292 <kbd_proc_data+0xd5>

f01002ef <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002ef:	55                   	push   %ebp
f01002f0:	89 e5                	mov    %esp,%ebp
f01002f2:	57                   	push   %edi
f01002f3:	56                   	push   %esi
f01002f4:	53                   	push   %ebx
f01002f5:	83 ec 1c             	sub    $0x1c,%esp
f01002f8:	e8 52 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002fd:	81 c3 0f 70 01 00    	add    $0x1700f,%ebx
f0100303:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100306:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100310:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100315:	eb 09                	jmp    f0100320 <cons_putc+0x31>
f0100317:	89 ca                	mov    %ecx,%edx
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	ec                   	in     (%dx),%al
	     i++)
f010031d:	83 c6 01             	add    $0x1,%esi
f0100320:	89 fa                	mov    %edi,%edx
f0100322:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100323:	a8 20                	test   $0x20,%al
f0100325:	75 08                	jne    f010032f <cons_putc+0x40>
f0100327:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032d:	7e e8                	jle    f0100317 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f010032f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100332:	89 f8                	mov    %edi,%eax
f0100334:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100337:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010033c:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010033d:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100342:	bf 79 03 00 00       	mov    $0x379,%edi
f0100347:	b9 84 00 00 00       	mov    $0x84,%ecx
f010034c:	eb 09                	jmp    f0100357 <cons_putc+0x68>
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ec                   	in     (%dx),%al
f0100351:	ec                   	in     (%dx),%al
f0100352:	ec                   	in     (%dx),%al
f0100353:	ec                   	in     (%dx),%al
f0100354:	83 c6 01             	add    $0x1,%esi
f0100357:	89 fa                	mov    %edi,%edx
f0100359:	ec                   	in     (%dx),%al
f010035a:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100360:	7f 04                	jg     f0100366 <cons_putc+0x77>
f0100362:	84 c0                	test   %al,%al
f0100364:	79 e8                	jns    f010034e <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100366:	ba 78 03 00 00       	mov    $0x378,%edx
f010036b:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010036f:	ee                   	out    %al,(%dx)
f0100370:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100375:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037a:	ee                   	out    %al,(%dx)
f010037b:	b8 08 00 00 00       	mov    $0x8,%eax
f0100380:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100381:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100384:	89 fa                	mov    %edi,%edx
f0100386:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010038c:	89 f8                	mov    %edi,%eax
f010038e:	80 cc 07             	or     $0x7,%ah
f0100391:	85 d2                	test   %edx,%edx
f0100393:	0f 45 c7             	cmovne %edi,%eax
f0100396:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100399:	0f b6 c0             	movzbl %al,%eax
f010039c:	83 f8 09             	cmp    $0x9,%eax
f010039f:	0f 84 b9 00 00 00    	je     f010045e <cons_putc+0x16f>
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	7e 74                	jle    f010041e <cons_putc+0x12f>
f01003aa:	83 f8 0a             	cmp    $0xa,%eax
f01003ad:	0f 84 9e 00 00 00    	je     f0100451 <cons_putc+0x162>
f01003b3:	83 f8 0d             	cmp    $0xd,%eax
f01003b6:	0f 85 d9 00 00 00    	jne    f0100495 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003bc:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f01003c3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c9:	c1 e8 16             	shr    $0x16,%eax
f01003cc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003cf:	c1 e0 04             	shl    $0x4,%eax
f01003d2:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003d9:	66 81 bb 7c 1f 00 00 	cmpw   $0x7cf,0x1f7c(%ebx)
f01003e0:	cf 07 
f01003e2:	0f 87 d4 00 00 00    	ja     f01004bc <cons_putc+0x1cd>
	outb(addr_6845, 14);
f01003e8:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01003ee:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003f3:	89 ca                	mov    %ecx,%edx
f01003f5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003f6:	0f b7 9b 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%ebx
f01003fd:	8d 71 01             	lea    0x1(%ecx),%esi
f0100400:	89 d8                	mov    %ebx,%eax
f0100402:	66 c1 e8 08          	shr    $0x8,%ax
f0100406:	89 f2                	mov    %esi,%edx
f0100408:	ee                   	out    %al,(%dx)
f0100409:	b8 0f 00 00 00       	mov    $0xf,%eax
f010040e:	89 ca                	mov    %ecx,%edx
f0100410:	ee                   	out    %al,(%dx)
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	89 f2                	mov    %esi,%edx
f0100415:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100416:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100419:	5b                   	pop    %ebx
f010041a:	5e                   	pop    %esi
f010041b:	5f                   	pop    %edi
f010041c:	5d                   	pop    %ebp
f010041d:	c3                   	ret    
	switch (c & 0xff) {
f010041e:	83 f8 08             	cmp    $0x8,%eax
f0100421:	75 72                	jne    f0100495 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f0100423:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f010042a:	66 85 c0             	test   %ax,%ax
f010042d:	74 b9                	je     f01003e8 <cons_putc+0xf9>
			crt_pos--;
f010042f:	83 e8 01             	sub    $0x1,%eax
f0100432:	66 89 83 7c 1f 00 00 	mov    %ax,0x1f7c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100440:	b2 00                	mov    $0x0,%dl
f0100442:	83 ca 20             	or     $0x20,%edx
f0100445:	8b 8b 80 1f 00 00    	mov    0x1f80(%ebx),%ecx
f010044b:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010044f:	eb 88                	jmp    f01003d9 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100451:	66 83 83 7c 1f 00 00 	addw   $0x50,0x1f7c(%ebx)
f0100458:	50 
f0100459:	e9 5e ff ff ff       	jmp    f01003bc <cons_putc+0xcd>
		cons_putc(' ');
f010045e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100463:	e8 87 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100468:	b8 20 00 00 00       	mov    $0x20,%eax
f010046d:	e8 7d fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100472:	b8 20 00 00 00       	mov    $0x20,%eax
f0100477:	e8 73 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f010047c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100481:	e8 69 fe ff ff       	call   f01002ef <cons_putc>
		cons_putc(' ');
f0100486:	b8 20 00 00 00       	mov    $0x20,%eax
f010048b:	e8 5f fe ff ff       	call   f01002ef <cons_putc>
f0100490:	e9 44 ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100495:	0f b7 83 7c 1f 00 00 	movzwl 0x1f7c(%ebx),%eax
f010049c:	8d 50 01             	lea    0x1(%eax),%edx
f010049f:	66 89 93 7c 1f 00 00 	mov    %dx,0x1f7c(%ebx)
f01004a6:	0f b7 c0             	movzwl %ax,%eax
f01004a9:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f01004af:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004b3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b7:	e9 1d ff ff ff       	jmp    f01003d9 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004bc:	8b 83 80 1f 00 00    	mov    0x1f80(%ebx),%eax
f01004c2:	83 ec 04             	sub    $0x4,%esp
f01004c5:	68 00 0f 00 00       	push   $0xf00
f01004ca:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d0:	52                   	push   %edx
f01004d1:	50                   	push   %eax
f01004d2:	e8 2d 3a 00 00       	call   f0103f04 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004d7:	8b 93 80 1f 00 00    	mov    0x1f80(%ebx),%edx
f01004dd:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004e3:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004e9:	83 c4 10             	add    $0x10,%esp
f01004ec:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004f1:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f4:	39 d0                	cmp    %edx,%eax
f01004f6:	75 f4                	jne    f01004ec <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f01004f8:	66 83 ab 7c 1f 00 00 	subw   $0x50,0x1f7c(%ebx)
f01004ff:	50 
f0100500:	e9 e3 fe ff ff       	jmp    f01003e8 <cons_putc+0xf9>

f0100505 <serial_intr>:
{
f0100505:	e8 e7 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010050a:	05 02 6e 01 00       	add    $0x16e02,%eax
	if (serial_exists)
f010050f:	80 b8 88 1f 00 00 00 	cmpb   $0x0,0x1f88(%eax)
f0100516:	75 02                	jne    f010051a <serial_intr+0x15>
f0100518:	f3 c3                	repz ret 
{
f010051a:	55                   	push   %ebp
f010051b:	89 e5                	mov    %esp,%ebp
f010051d:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100520:	8d 80 47 8e fe ff    	lea    -0x171b9(%eax),%eax
f0100526:	e8 47 fc ff ff       	call   f0100172 <cons_intr>
}
f010052b:	c9                   	leave  
f010052c:	c3                   	ret    

f010052d <kbd_intr>:
{
f010052d:	55                   	push   %ebp
f010052e:	89 e5                	mov    %esp,%ebp
f0100530:	83 ec 08             	sub    $0x8,%esp
f0100533:	e8 b9 01 00 00       	call   f01006f1 <__x86.get_pc_thunk.ax>
f0100538:	05 d4 6d 01 00       	add    $0x16dd4,%eax
	cons_intr(kbd_proc_data);
f010053d:	8d 80 b1 8e fe ff    	lea    -0x1714f(%eax),%eax
f0100543:	e8 2a fc ff ff       	call   f0100172 <cons_intr>
}
f0100548:	c9                   	leave  
f0100549:	c3                   	ret    

f010054a <cons_getc>:
{
f010054a:	55                   	push   %ebp
f010054b:	89 e5                	mov    %esp,%ebp
f010054d:	53                   	push   %ebx
f010054e:	83 ec 04             	sub    $0x4,%esp
f0100551:	e8 f9 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100556:	81 c3 b6 6d 01 00    	add    $0x16db6,%ebx
	serial_intr();
f010055c:	e8 a4 ff ff ff       	call   f0100505 <serial_intr>
	kbd_intr();
f0100561:	e8 c7 ff ff ff       	call   f010052d <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100566:	8b 93 74 1f 00 00    	mov    0x1f74(%ebx),%edx
	return 0;
f010056c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100571:	3b 93 78 1f 00 00    	cmp    0x1f78(%ebx),%edx
f0100577:	74 19                	je     f0100592 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100579:	8d 4a 01             	lea    0x1(%edx),%ecx
f010057c:	89 8b 74 1f 00 00    	mov    %ecx,0x1f74(%ebx)
f0100582:	0f b6 84 13 74 1d 00 	movzbl 0x1d74(%ebx,%edx,1),%eax
f0100589:	00 
		if (cons.rpos == CONSBUFSIZE)
f010058a:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100590:	74 06                	je     f0100598 <cons_getc+0x4e>
}
f0100592:	83 c4 04             	add    $0x4,%esp
f0100595:	5b                   	pop    %ebx
f0100596:	5d                   	pop    %ebp
f0100597:	c3                   	ret    
			cons.rpos = 0;
f0100598:	c7 83 74 1f 00 00 00 	movl   $0x0,0x1f74(%ebx)
f010059f:	00 00 00 
f01005a2:	eb ee                	jmp    f0100592 <cons_getc+0x48>

f01005a4 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a4:	55                   	push   %ebp
f01005a5:	89 e5                	mov    %esp,%ebp
f01005a7:	57                   	push   %edi
f01005a8:	56                   	push   %esi
f01005a9:	53                   	push   %ebx
f01005aa:	83 ec 1c             	sub    $0x1c,%esp
f01005ad:	e8 9d fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b2:	81 c3 5a 6d 01 00    	add    $0x16d5a,%ebx
	was = *cp;
f01005b8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005bf:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c6:	5a a5 
	if (*cp != 0xA55A) {
f01005c8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005cf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005d3:	0f 84 bc 00 00 00    	je     f0100695 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005d9:	c7 83 84 1f 00 00 b4 	movl   $0x3b4,0x1f84(%ebx)
f01005e0:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005e3:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005ea:	8b bb 84 1f 00 00    	mov    0x1f84(%ebx),%edi
f01005f0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005f5:	89 fa                	mov    %edi,%edx
f01005f7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f8:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005fb:	89 ca                	mov    %ecx,%edx
f01005fd:	ec                   	in     (%dx),%al
f01005fe:	0f b6 f0             	movzbl %al,%esi
f0100601:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100604:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100609:	89 fa                	mov    %edi,%edx
f010060b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060c:	89 ca                	mov    %ecx,%edx
f010060e:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100612:	89 bb 80 1f 00 00    	mov    %edi,0x1f80(%ebx)
	pos |= inb(addr_6845 + 1);
f0100618:	0f b6 c0             	movzbl %al,%eax
f010061b:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010061d:	66 89 b3 7c 1f 00 00 	mov    %si,0x1f7c(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100624:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100629:	89 c8                	mov    %ecx,%eax
f010062b:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100630:	ee                   	out    %al,(%dx)
f0100631:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100636:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010063b:	89 fa                	mov    %edi,%edx
f010063d:	ee                   	out    %al,(%dx)
f010063e:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100643:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	be f9 03 00 00       	mov    $0x3f9,%esi
f010064e:	89 c8                	mov    %ecx,%eax
f0100650:	89 f2                	mov    %esi,%edx
f0100652:	ee                   	out    %al,(%dx)
f0100653:	b8 03 00 00 00       	mov    $0x3,%eax
f0100658:	89 fa                	mov    %edi,%edx
f010065a:	ee                   	out    %al,(%dx)
f010065b:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100660:	89 c8                	mov    %ecx,%eax
f0100662:	ee                   	out    %al,(%dx)
f0100663:	b8 01 00 00 00       	mov    $0x1,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010066b:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100670:	ec                   	in     (%dx),%al
f0100671:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100673:	3c ff                	cmp    $0xff,%al
f0100675:	0f 95 83 88 1f 00 00 	setne  0x1f88(%ebx)
f010067c:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100681:	ec                   	in     (%dx),%al
f0100682:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100687:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100688:	80 f9 ff             	cmp    $0xff,%cl
f010068b:	74 25                	je     f01006b2 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010068d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100690:	5b                   	pop    %ebx
f0100691:	5e                   	pop    %esi
f0100692:	5f                   	pop    %edi
f0100693:	5d                   	pop    %ebp
f0100694:	c3                   	ret    
		*cp = was;
f0100695:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069c:	c7 83 84 1f 00 00 d4 	movl   $0x3d4,0x1f84(%ebx)
f01006a3:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a6:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006ad:	e9 38 ff ff ff       	jmp    f01005ea <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006b2:	83 ec 0c             	sub    $0xc,%esp
f01006b5:	8d 83 4d d0 fe ff    	lea    -0x12fb3(%ebx),%eax
f01006bb:	50                   	push   %eax
f01006bc:	e8 ad 2b 00 00       	call   f010326e <cprintf>
f01006c1:	83 c4 10             	add    $0x10,%esp
}
f01006c4:	eb c7                	jmp    f010068d <cons_init+0xe9>

f01006c6 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01006cf:	e8 1b fc ff ff       	call   f01002ef <cons_putc>
}
f01006d4:	c9                   	leave  
f01006d5:	c3                   	ret    

f01006d6 <getchar>:

int
getchar(void)
{
f01006d6:	55                   	push   %ebp
f01006d7:	89 e5                	mov    %esp,%ebp
f01006d9:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006dc:	e8 69 fe ff ff       	call   f010054a <cons_getc>
f01006e1:	85 c0                	test   %eax,%eax
f01006e3:	74 f7                	je     f01006dc <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006e5:	c9                   	leave  
f01006e6:	c3                   	ret    

f01006e7 <iscons>:

int
iscons(int fdnum)
{
f01006e7:	55                   	push   %ebp
f01006e8:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01006ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01006ef:	5d                   	pop    %ebp
f01006f0:	c3                   	ret    

f01006f1 <__x86.get_pc_thunk.ax>:
f01006f1:	8b 04 24             	mov    (%esp),%eax
f01006f4:	c3                   	ret    

f01006f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	56                   	push   %esi
f01006f9:	53                   	push   %ebx
f01006fa:	e8 50 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ff:	81 c3 0d 6c 01 00    	add    $0x16c0d,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100705:	83 ec 04             	sub    $0x4,%esp
f0100708:	8d 83 74 d2 fe ff    	lea    -0x12d8c(%ebx),%eax
f010070e:	50                   	push   %eax
f010070f:	8d 83 92 d2 fe ff    	lea    -0x12d6e(%ebx),%eax
f0100715:	50                   	push   %eax
f0100716:	8d b3 97 d2 fe ff    	lea    -0x12d69(%ebx),%esi
f010071c:	56                   	push   %esi
f010071d:	e8 4c 2b 00 00       	call   f010326e <cprintf>
f0100722:	83 c4 0c             	add    $0xc,%esp
f0100725:	8d 83 44 d3 fe ff    	lea    -0x12cbc(%ebx),%eax
f010072b:	50                   	push   %eax
f010072c:	8d 83 a0 d2 fe ff    	lea    -0x12d60(%ebx),%eax
f0100732:	50                   	push   %eax
f0100733:	56                   	push   %esi
f0100734:	e8 35 2b 00 00       	call   f010326e <cprintf>
f0100739:	83 c4 0c             	add    $0xc,%esp
f010073c:	8d 83 a9 d2 fe ff    	lea    -0x12d57(%ebx),%eax
f0100742:	50                   	push   %eax
f0100743:	8d 83 c0 d2 fe ff    	lea    -0x12d40(%ebx),%eax
f0100749:	50                   	push   %eax
f010074a:	56                   	push   %esi
f010074b:	e8 1e 2b 00 00       	call   f010326e <cprintf>
	return 0;
}
f0100750:	b8 00 00 00 00       	mov    $0x0,%eax
f0100755:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100758:	5b                   	pop    %ebx
f0100759:	5e                   	pop    %esi
f010075a:	5d                   	pop    %ebp
f010075b:	c3                   	ret    

f010075c <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010075c:	55                   	push   %ebp
f010075d:	89 e5                	mov    %esp,%ebp
f010075f:	57                   	push   %edi
f0100760:	56                   	push   %esi
f0100761:	53                   	push   %ebx
f0100762:	83 ec 18             	sub    $0x18,%esp
f0100765:	e8 e5 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010076a:	81 c3 a2 6b 01 00    	add    $0x16ba2,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100770:	8d 83 ca d2 fe ff    	lea    -0x12d36(%ebx),%eax
f0100776:	50                   	push   %eax
f0100777:	e8 f2 2a 00 00       	call   f010326e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f0100785:	8d 83 6c d3 fe ff    	lea    -0x12c94(%ebx),%eax
f010078b:	50                   	push   %eax
f010078c:	e8 dd 2a 00 00       	call   f010326e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100791:	83 c4 0c             	add    $0xc,%esp
f0100794:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079a:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a0:	50                   	push   %eax
f01007a1:	57                   	push   %edi
f01007a2:	8d 83 94 d3 fe ff    	lea    -0x12c6c(%ebx),%eax
f01007a8:	50                   	push   %eax
f01007a9:	e8 c0 2a 00 00       	call   f010326e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007ae:	83 c4 0c             	add    $0xc,%esp
f01007b1:	c7 c0 f9 42 10 f0    	mov    $0xf01042f9,%eax
f01007b7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007bd:	52                   	push   %edx
f01007be:	50                   	push   %eax
f01007bf:	8d 83 b8 d3 fe ff    	lea    -0x12c48(%ebx),%eax
f01007c5:	50                   	push   %eax
f01007c6:	e8 a3 2a 00 00       	call   f010326e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cb:	83 c4 0c             	add    $0xc,%esp
f01007ce:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007d4:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007da:	52                   	push   %edx
f01007db:	50                   	push   %eax
f01007dc:	8d 83 dc d3 fe ff    	lea    -0x12c24(%ebx),%eax
f01007e2:	50                   	push   %eax
f01007e3:	e8 86 2a 00 00       	call   f010326e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e8:	83 c4 0c             	add    $0xc,%esp
f01007eb:	c7 c6 c0 96 11 f0    	mov    $0xf01196c0,%esi
f01007f1:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f7:	50                   	push   %eax
f01007f8:	56                   	push   %esi
f01007f9:	8d 83 00 d4 fe ff    	lea    -0x12c00(%ebx),%eax
f01007ff:	50                   	push   %eax
f0100800:	e8 69 2a 00 00       	call   f010326e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100805:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100808:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080e:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100810:	c1 fe 0a             	sar    $0xa,%esi
f0100813:	56                   	push   %esi
f0100814:	8d 83 24 d4 fe ff    	lea    -0x12bdc(%ebx),%eax
f010081a:	50                   	push   %eax
f010081b:	e8 4e 2a 00 00       	call   f010326e <cprintf>
	return 0;
}
f0100820:	b8 00 00 00 00       	mov    $0x0,%eax
f0100825:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100828:	5b                   	pop    %ebx
f0100829:	5e                   	pop    %esi
f010082a:	5f                   	pop    %edi
f010082b:	5d                   	pop    %ebp
f010082c:	c3                   	ret    

f010082d <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010082d:	55                   	push   %ebp
f010082e:	89 e5                	mov    %esp,%ebp
f0100830:	57                   	push   %edi
f0100831:	56                   	push   %esi
f0100832:	53                   	push   %ebx
f0100833:	83 ec 48             	sub    $0x48,%esp
f0100836:	e8 14 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010083b:	81 c3 d1 6a 01 00    	add    $0x16ad1,%ebx

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100841:	89 ee                	mov    %ebp,%esi
 	uint32_t ebp, *ptr_ebp;
    struct Eipdebuginfo info;
    ebp = read_ebp();
    cprintf("Stack backtrace:\n");
f0100843:	8d 83 e3 d2 fe ff    	lea    -0x12d1d(%ebx),%eax
f0100849:	50                   	push   %eax
f010084a:	e8 1f 2a 00 00       	call   f010326e <cprintf>
    while (ebp != 0) {
f010084f:	83 c4 10             	add    $0x10,%esp
        ptr_ebp = (uint32_t *)ebp;
        cprintf("\tebp %x  eip %x  args %08x %08x %08x %08x %08x\n", ebp, ptr_ebp[1], ptr_ebp[2], ptr_ebp[3], ptr_ebp[4], ptr_ebp[5], ptr_ebp[6]);
f0100852:	8d 83 50 d4 fe ff    	lea    -0x12bb0(%ebx),%eax
f0100858:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        if (debuginfo_eip(ptr_ebp[1], &info) == 0) {
f010085b:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010085e:	89 45 c0             	mov    %eax,-0x40(%ebp)
    while (ebp != 0) {
f0100861:	eb 02                	jmp    f0100865 <mon_backtrace+0x38>
            uint32_t fn_offset = ptr_ebp[1] - info.eip_fn_addr;
            cprintf("\t\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line,info.eip_fn_namelen,  info.eip_fn_name, fn_offset);
        }
        ebp = *ptr_ebp;
f0100863:	8b 37                	mov    (%edi),%esi
    while (ebp != 0) {
f0100865:	85 f6                	test   %esi,%esi
f0100867:	74 59                	je     f01008c2 <mon_backtrace+0x95>
        ptr_ebp = (uint32_t *)ebp;
f0100869:	89 f7                	mov    %esi,%edi
        cprintf("\tebp %x  eip %x  args %08x %08x %08x %08x %08x\n", ebp, ptr_ebp[1], ptr_ebp[2], ptr_ebp[3], ptr_ebp[4], ptr_ebp[5], ptr_ebp[6]);
f010086b:	ff 76 18             	pushl  0x18(%esi)
f010086e:	ff 76 14             	pushl  0x14(%esi)
f0100871:	ff 76 10             	pushl  0x10(%esi)
f0100874:	ff 76 0c             	pushl  0xc(%esi)
f0100877:	ff 76 08             	pushl  0x8(%esi)
f010087a:	ff 76 04             	pushl  0x4(%esi)
f010087d:	56                   	push   %esi
f010087e:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100881:	e8 e8 29 00 00       	call   f010326e <cprintf>
        if (debuginfo_eip(ptr_ebp[1], &info) == 0) {
f0100886:	83 c4 18             	add    $0x18,%esp
f0100889:	ff 75 c0             	pushl  -0x40(%ebp)
f010088c:	ff 76 04             	pushl  0x4(%esi)
f010088f:	e8 de 2a 00 00       	call   f0103372 <debuginfo_eip>
f0100894:	83 c4 10             	add    $0x10,%esp
f0100897:	85 c0                	test   %eax,%eax
f0100899:	75 c8                	jne    f0100863 <mon_backtrace+0x36>
            cprintf("\t\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line,info.eip_fn_namelen,  info.eip_fn_name, fn_offset);
f010089b:	83 ec 08             	sub    $0x8,%esp
            uint32_t fn_offset = ptr_ebp[1] - info.eip_fn_addr;
f010089e:	8b 46 04             	mov    0x4(%esi),%eax
f01008a1:	2b 45 e0             	sub    -0x20(%ebp),%eax
            cprintf("\t\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line,info.eip_fn_namelen,  info.eip_fn_name, fn_offset);
f01008a4:	50                   	push   %eax
f01008a5:	ff 75 d8             	pushl  -0x28(%ebp)
f01008a8:	ff 75 dc             	pushl  -0x24(%ebp)
f01008ab:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008ae:	ff 75 d0             	pushl  -0x30(%ebp)
f01008b1:	8d 83 f5 d2 fe ff    	lea    -0x12d0b(%ebx),%eax
f01008b7:	50                   	push   %eax
f01008b8:	e8 b1 29 00 00       	call   f010326e <cprintf>
f01008bd:	83 c4 20             	add    $0x20,%esp
f01008c0:	eb a1                	jmp    f0100863 <mon_backtrace+0x36>
    }
    return 0;
}
f01008c2:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ca:	5b                   	pop    %ebx
f01008cb:	5e                   	pop    %esi
f01008cc:	5f                   	pop    %edi
f01008cd:	5d                   	pop    %ebp
f01008ce:	c3                   	ret    

f01008cf <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008cf:	55                   	push   %ebp
f01008d0:	89 e5                	mov    %esp,%ebp
f01008d2:	57                   	push   %edi
f01008d3:	56                   	push   %esi
f01008d4:	53                   	push   %ebx
f01008d5:	83 ec 68             	sub    $0x68,%esp
f01008d8:	e8 72 f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01008dd:	81 c3 2f 6a 01 00    	add    $0x16a2f,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008e3:	8d 83 80 d4 fe ff    	lea    -0x12b80(%ebx),%eax
f01008e9:	50                   	push   %eax
f01008ea:	e8 7f 29 00 00       	call   f010326e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008ef:	8d 83 a4 d4 fe ff    	lea    -0x12b5c(%ebx),%eax
f01008f5:	89 04 24             	mov    %eax,(%esp)
f01008f8:	e8 71 29 00 00       	call   f010326e <cprintf>
f01008fd:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100900:	8d bb 0b d3 fe ff    	lea    -0x12cf5(%ebx),%edi
f0100906:	eb 4a                	jmp    f0100952 <monitor+0x83>
f0100908:	83 ec 08             	sub    $0x8,%esp
f010090b:	0f be c0             	movsbl %al,%eax
f010090e:	50                   	push   %eax
f010090f:	57                   	push   %edi
f0100910:	e8 65 35 00 00       	call   f0103e7a <strchr>
f0100915:	83 c4 10             	add    $0x10,%esp
f0100918:	85 c0                	test   %eax,%eax
f010091a:	74 08                	je     f0100924 <monitor+0x55>
			*buf++ = 0;
f010091c:	c6 06 00             	movb   $0x0,(%esi)
f010091f:	8d 76 01             	lea    0x1(%esi),%esi
f0100922:	eb 79                	jmp    f010099d <monitor+0xce>
		if (*buf == 0)
f0100924:	80 3e 00             	cmpb   $0x0,(%esi)
f0100927:	74 7f                	je     f01009a8 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100929:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f010092d:	74 0f                	je     f010093e <monitor+0x6f>
		argv[argc++] = buf;
f010092f:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100932:	8d 48 01             	lea    0x1(%eax),%ecx
f0100935:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100938:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010093c:	eb 44                	jmp    f0100982 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010093e:	83 ec 08             	sub    $0x8,%esp
f0100941:	6a 10                	push   $0x10
f0100943:	8d 83 10 d3 fe ff    	lea    -0x12cf0(%ebx),%eax
f0100949:	50                   	push   %eax
f010094a:	e8 1f 29 00 00       	call   f010326e <cprintf>
f010094f:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100952:	8d 83 07 d3 fe ff    	lea    -0x12cf9(%ebx),%eax
f0100958:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f010095b:	83 ec 0c             	sub    $0xc,%esp
f010095e:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100961:	e8 dc 32 00 00       	call   f0103c42 <readline>
f0100966:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100968:	83 c4 10             	add    $0x10,%esp
f010096b:	85 c0                	test   %eax,%eax
f010096d:	74 ec                	je     f010095b <monitor+0x8c>
	argv[argc] = 0;
f010096f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100976:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f010097d:	eb 1e                	jmp    f010099d <monitor+0xce>
			buf++;
f010097f:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100982:	0f b6 06             	movzbl (%esi),%eax
f0100985:	84 c0                	test   %al,%al
f0100987:	74 14                	je     f010099d <monitor+0xce>
f0100989:	83 ec 08             	sub    $0x8,%esp
f010098c:	0f be c0             	movsbl %al,%eax
f010098f:	50                   	push   %eax
f0100990:	57                   	push   %edi
f0100991:	e8 e4 34 00 00       	call   f0103e7a <strchr>
f0100996:	83 c4 10             	add    $0x10,%esp
f0100999:	85 c0                	test   %eax,%eax
f010099b:	74 e2                	je     f010097f <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f010099d:	0f b6 06             	movzbl (%esi),%eax
f01009a0:	84 c0                	test   %al,%al
f01009a2:	0f 85 60 ff ff ff    	jne    f0100908 <monitor+0x39>
	argv[argc] = 0;
f01009a8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009ab:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009b2:	00 
	if (argc == 0)
f01009b3:	85 c0                	test   %eax,%eax
f01009b5:	74 9b                	je     f0100952 <monitor+0x83>
f01009b7:	8d b3 14 1d 00 00    	lea    0x1d14(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009bd:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f01009c4:	83 ec 08             	sub    $0x8,%esp
f01009c7:	ff 36                	pushl  (%esi)
f01009c9:	ff 75 a8             	pushl  -0x58(%ebp)
f01009cc:	e8 4b 34 00 00       	call   f0103e1c <strcmp>
f01009d1:	83 c4 10             	add    $0x10,%esp
f01009d4:	85 c0                	test   %eax,%eax
f01009d6:	74 29                	je     f0100a01 <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009d8:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f01009dc:	8b 45 a0             	mov    -0x60(%ebp),%eax
f01009df:	83 c6 0c             	add    $0xc,%esi
f01009e2:	83 f8 03             	cmp    $0x3,%eax
f01009e5:	75 dd                	jne    f01009c4 <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009e7:	83 ec 08             	sub    $0x8,%esp
f01009ea:	ff 75 a8             	pushl  -0x58(%ebp)
f01009ed:	8d 83 2d d3 fe ff    	lea    -0x12cd3(%ebx),%eax
f01009f3:	50                   	push   %eax
f01009f4:	e8 75 28 00 00       	call   f010326e <cprintf>
f01009f9:	83 c4 10             	add    $0x10,%esp
f01009fc:	e9 51 ff ff ff       	jmp    f0100952 <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100a01:	83 ec 04             	sub    $0x4,%esp
f0100a04:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100a07:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a0a:	ff 75 08             	pushl  0x8(%ebp)
f0100a0d:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a10:	52                   	push   %edx
f0100a11:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a14:	ff 94 83 1c 1d 00 00 	call   *0x1d1c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a1b:	83 c4 10             	add    $0x10,%esp
f0100a1e:	85 c0                	test   %eax,%eax
f0100a20:	0f 89 2c ff ff ff    	jns    f0100952 <monitor+0x83>
				break;
	}
}
f0100a26:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a29:	5b                   	pop    %ebx
f0100a2a:	5e                   	pop    %esi
f0100a2b:	5f                   	pop    %edi
f0100a2c:	5d                   	pop    %ebp
f0100a2d:	c3                   	ret    

f0100a2e <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a2e:	55                   	push   %ebp
f0100a2f:	89 e5                	mov    %esp,%ebp
f0100a31:	57                   	push   %edi
f0100a32:	56                   	push   %esi
f0100a33:	53                   	push   %ebx
f0100a34:	83 ec 18             	sub    $0x18,%esp
f0100a37:	e8 13 f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a3c:	81 c3 d0 68 01 00    	add    $0x168d0,%ebx
f0100a42:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a44:	50                   	push   %eax
f0100a45:	e8 9d 27 00 00       	call   f01031e7 <mc146818_read>
f0100a4a:	89 c6                	mov    %eax,%esi
f0100a4c:	83 c7 01             	add    $0x1,%edi
f0100a4f:	89 3c 24             	mov    %edi,(%esp)
f0100a52:	e8 90 27 00 00       	call   f01031e7 <mc146818_read>
f0100a57:	c1 e0 08             	shl    $0x8,%eax
f0100a5a:	09 f0                	or     %esi,%eax
}
f0100a5c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a5f:	5b                   	pop    %ebx
f0100a60:	5e                   	pop    %esi
f0100a61:	5f                   	pop    %edi
f0100a62:	5d                   	pop    %ebp
f0100a63:	c3                   	ret    

f0100a64 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a64:	55                   	push   %ebp
f0100a65:	89 e5                	mov    %esp,%ebp
f0100a67:	56                   	push   %esi
f0100a68:	53                   	push   %ebx
f0100a69:	e8 71 27 00 00       	call   f01031df <__x86.get_pc_thunk.cx>
f0100a6e:	81 c1 9e 68 01 00    	add    $0x1689e,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a74:	89 d3                	mov    %edx,%ebx
f0100a76:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100a79:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100a7c:	a8 01                	test   $0x1,%al
f0100a7e:	74 5a                	je     f0100ada <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a80:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a85:	89 c6                	mov    %eax,%esi
f0100a87:	c1 ee 0c             	shr    $0xc,%esi
f0100a8a:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0100a90:	3b 33                	cmp    (%ebx),%esi
f0100a92:	73 2b                	jae    f0100abf <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100a94:	c1 ea 0c             	shr    $0xc,%edx
f0100a97:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a9d:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100aa4:	89 c2                	mov    %eax,%edx
f0100aa6:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aa9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aae:	85 d2                	test   %edx,%edx
f0100ab0:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ab5:	0f 44 c2             	cmove  %edx,%eax
}
f0100ab8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100abb:	5b                   	pop    %ebx
f0100abc:	5e                   	pop    %esi
f0100abd:	5d                   	pop    %ebp
f0100abe:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100abf:	50                   	push   %eax
f0100ac0:	8d 81 cc d4 fe ff    	lea    -0x12b34(%ecx),%eax
f0100ac6:	50                   	push   %eax
f0100ac7:	68 2d 03 00 00       	push   $0x32d
f0100acc:	8d 81 d4 dc fe ff    	lea    -0x1232c(%ecx),%eax
f0100ad2:	50                   	push   %eax
f0100ad3:	89 cb                	mov    %ecx,%ebx
f0100ad5:	e8 bf f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100ada:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100adf:	eb d7                	jmp    f0100ab8 <check_va2pa+0x54>

f0100ae1 <boot_alloc>:
{
f0100ae1:	55                   	push   %ebp
f0100ae2:	89 e5                	mov    %esp,%ebp
f0100ae4:	53                   	push   %ebx
f0100ae5:	83 ec 04             	sub    $0x4,%esp
f0100ae8:	e8 62 f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100aed:	81 c3 1f 68 01 00    	add    $0x1681f,%ebx
	if (!nextfree) {
f0100af3:	83 bb 8c 1f 00 00 00 	cmpl   $0x0,0x1f8c(%ebx)
f0100afa:	74 39                	je     f0100b35 <boot_alloc+0x54>
	result = nextfree;
f0100afc:	8b 8b 8c 1f 00 00    	mov    0x1f8c(%ebx),%ecx
	nextfree = ROUNDUP(result + n, PGSIZE);
f0100b02:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100b09:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b0f:	89 93 8c 1f 00 00    	mov    %edx,0x1f8c(%ebx)
	if ((uint32_t)kva < KERNBASE)
f0100b15:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100b1b:	76 32                	jbe    f0100b4f <boot_alloc+0x6e>
	return (physaddr_t)kva - KERNBASE;
f0100b1d:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
	if (PADDR(nextfree)>=0x400000 || nextfree < result)
f0100b23:	3d ff ff 3f 00       	cmp    $0x3fffff,%eax
f0100b28:	77 3b                	ja     f0100b65 <boot_alloc+0x84>
f0100b2a:	39 d1                	cmp    %edx,%ecx
f0100b2c:	77 37                	ja     f0100b65 <boot_alloc+0x84>
}
f0100b2e:	89 c8                	mov    %ecx,%eax
f0100b30:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b33:	c9                   	leave  
f0100b34:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b35:	c7 c2 c0 96 11 f0    	mov    $0xf01196c0,%edx
f0100b3b:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100b41:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b47:	89 93 8c 1f 00 00    	mov    %edx,0x1f8c(%ebx)
f0100b4d:	eb ad                	jmp    f0100afc <boot_alloc+0x1b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100b4f:	52                   	push   %edx
f0100b50:	8d 83 f0 d4 fe ff    	lea    -0x12b10(%ebx),%eax
f0100b56:	50                   	push   %eax
f0100b57:	6a 6d                	push   $0x6d
f0100b59:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100b5f:	50                   	push   %eax
f0100b60:	e8 34 f5 ff ff       	call   f0100099 <_panic>
		cprintf("nextfree:%u\n",nextfree);
f0100b65:	83 ec 08             	sub    $0x8,%esp
f0100b68:	52                   	push   %edx
f0100b69:	8d 83 e0 dc fe ff    	lea    -0x12320(%ebx),%eax
f0100b6f:	50                   	push   %eax
f0100b70:	e8 f9 26 00 00       	call   f010326e <cprintf>
		panic("nextfree's value is not correct\n");
f0100b75:	83 c4 0c             	add    $0xc,%esp
f0100b78:	8d 83 14 d5 fe ff    	lea    -0x12aec(%ebx),%eax
f0100b7e:	50                   	push   %eax
f0100b7f:	6a 70                	push   $0x70
f0100b81:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100b87:	50                   	push   %eax
f0100b88:	e8 0c f5 ff ff       	call   f0100099 <_panic>

f0100b8d <check_page_free_list>:
{
f0100b8d:	55                   	push   %ebp
f0100b8e:	89 e5                	mov    %esp,%ebp
f0100b90:	57                   	push   %edi
f0100b91:	56                   	push   %esi
f0100b92:	53                   	push   %ebx
f0100b93:	83 ec 3c             	sub    $0x3c,%esp
f0100b96:	e8 48 26 00 00       	call   f01031e3 <__x86.get_pc_thunk.di>
f0100b9b:	81 c7 71 67 01 00    	add    $0x16771,%edi
f0100ba1:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ba4:	84 c0                	test   %al,%al
f0100ba6:	0f 85 dd 02 00 00    	jne    f0100e89 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100bac:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100baf:	83 b8 90 1f 00 00 00 	cmpl   $0x0,0x1f90(%eax)
f0100bb6:	74 0c                	je     f0100bc4 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bb8:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100bbf:	e9 2f 03 00 00       	jmp    f0100ef3 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100bc4:	83 ec 04             	sub    $0x4,%esp
f0100bc7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bca:	8d 83 38 d5 fe ff    	lea    -0x12ac8(%ebx),%eax
f0100bd0:	50                   	push   %eax
f0100bd1:	68 6e 02 00 00       	push   $0x26e
f0100bd6:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100bdc:	50                   	push   %eax
f0100bdd:	e8 b7 f4 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100be2:	50                   	push   %eax
f0100be3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100be6:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0100bec:	50                   	push   %eax
f0100bed:	6a 52                	push   $0x52
f0100bef:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0100bf5:	50                   	push   %eax
f0100bf6:	e8 9e f4 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bfb:	8b 36                	mov    (%esi),%esi
f0100bfd:	85 f6                	test   %esi,%esi
f0100bff:	74 40                	je     f0100c41 <check_page_free_list+0xb4>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c01:	89 f0                	mov    %esi,%eax
f0100c03:	2b 07                	sub    (%edi),%eax
f0100c05:	c1 f8 03             	sar    $0x3,%eax
f0100c08:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c0b:	89 c2                	mov    %eax,%edx
f0100c0d:	c1 ea 16             	shr    $0x16,%edx
f0100c10:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c13:	73 e6                	jae    f0100bfb <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100c15:	89 c2                	mov    %eax,%edx
f0100c17:	c1 ea 0c             	shr    $0xc,%edx
f0100c1a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c1d:	3b 11                	cmp    (%ecx),%edx
f0100c1f:	73 c1                	jae    f0100be2 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100c21:	83 ec 04             	sub    $0x4,%esp
f0100c24:	68 80 00 00 00       	push   $0x80
f0100c29:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c2e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c33:	50                   	push   %eax
f0100c34:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c37:	e8 7b 32 00 00       	call   f0103eb7 <memset>
f0100c3c:	83 c4 10             	add    $0x10,%esp
f0100c3f:	eb ba                	jmp    f0100bfb <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100c41:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c46:	e8 96 fe ff ff       	call   f0100ae1 <boot_alloc>
f0100c4b:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c4e:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c51:	8b 97 90 1f 00 00    	mov    0x1f90(%edi),%edx
		assert(pp >= pages);
f0100c57:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100c5d:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100c5f:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100c65:	8b 00                	mov    (%eax),%eax
f0100c67:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c6a:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c6d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c70:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c75:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c78:	e9 08 01 00 00       	jmp    f0100d85 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100c7d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c80:	8d 83 fb dc fe ff    	lea    -0x12305(%ebx),%eax
f0100c86:	50                   	push   %eax
f0100c87:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100c8d:	50                   	push   %eax
f0100c8e:	68 88 02 00 00       	push   $0x288
f0100c93:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100c99:	50                   	push   %eax
f0100c9a:	e8 fa f3 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100c9f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ca2:	8d 83 1c dd fe ff    	lea    -0x122e4(%ebx),%eax
f0100ca8:	50                   	push   %eax
f0100ca9:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100caf:	50                   	push   %eax
f0100cb0:	68 89 02 00 00       	push   $0x289
f0100cb5:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100cbb:	50                   	push   %eax
f0100cbc:	e8 d8 f3 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cc1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cc4:	8d 83 5c d5 fe ff    	lea    -0x12aa4(%ebx),%eax
f0100cca:	50                   	push   %eax
f0100ccb:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100cd1:	50                   	push   %eax
f0100cd2:	68 8a 02 00 00       	push   $0x28a
f0100cd7:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100cdd:	50                   	push   %eax
f0100cde:	e8 b6 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100ce3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ce6:	8d 83 30 dd fe ff    	lea    -0x122d0(%ebx),%eax
f0100cec:	50                   	push   %eax
f0100ced:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100cf3:	50                   	push   %eax
f0100cf4:	68 8d 02 00 00       	push   $0x28d
f0100cf9:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100cff:	50                   	push   %eax
f0100d00:	e8 94 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d05:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d08:	8d 83 41 dd fe ff    	lea    -0x122bf(%ebx),%eax
f0100d0e:	50                   	push   %eax
f0100d0f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100d15:	50                   	push   %eax
f0100d16:	68 8e 02 00 00       	push   $0x28e
f0100d1b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100d21:	50                   	push   %eax
f0100d22:	e8 72 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d27:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d2a:	8d 83 90 d5 fe ff    	lea    -0x12a70(%ebx),%eax
f0100d30:	50                   	push   %eax
f0100d31:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100d37:	50                   	push   %eax
f0100d38:	68 8f 02 00 00       	push   $0x28f
f0100d3d:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100d43:	50                   	push   %eax
f0100d44:	e8 50 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d49:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d4c:	8d 83 5a dd fe ff    	lea    -0x122a6(%ebx),%eax
f0100d52:	50                   	push   %eax
f0100d53:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100d59:	50                   	push   %eax
f0100d5a:	68 90 02 00 00       	push   $0x290
f0100d5f:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100d65:	50                   	push   %eax
f0100d66:	e8 2e f3 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100d6b:	89 c6                	mov    %eax,%esi
f0100d6d:	c1 ee 0c             	shr    $0xc,%esi
f0100d70:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100d73:	76 70                	jbe    f0100de5 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100d75:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d7a:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d7d:	77 7f                	ja     f0100dfe <check_page_free_list+0x271>
			++nfree_extmem;
f0100d7f:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d83:	8b 12                	mov    (%edx),%edx
f0100d85:	85 d2                	test   %edx,%edx
f0100d87:	0f 84 93 00 00 00    	je     f0100e20 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100d8d:	39 d1                	cmp    %edx,%ecx
f0100d8f:	0f 87 e8 fe ff ff    	ja     f0100c7d <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100d95:	39 d3                	cmp    %edx,%ebx
f0100d97:	0f 86 02 ff ff ff    	jbe    f0100c9f <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d9d:	89 d0                	mov    %edx,%eax
f0100d9f:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100da2:	a8 07                	test   $0x7,%al
f0100da4:	0f 85 17 ff ff ff    	jne    f0100cc1 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100daa:	c1 f8 03             	sar    $0x3,%eax
f0100dad:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100db0:	85 c0                	test   %eax,%eax
f0100db2:	0f 84 2b ff ff ff    	je     f0100ce3 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100db8:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100dbd:	0f 84 42 ff ff ff    	je     f0100d05 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dc3:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dc8:	0f 84 59 ff ff ff    	je     f0100d27 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dce:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dd3:	0f 84 70 ff ff ff    	je     f0100d49 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dd9:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100dde:	77 8b                	ja     f0100d6b <check_page_free_list+0x1de>
			++nfree_basemem;
f0100de0:	83 c7 01             	add    $0x1,%edi
f0100de3:	eb 9e                	jmp    f0100d83 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100de5:	50                   	push   %eax
f0100de6:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100de9:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0100def:	50                   	push   %eax
f0100df0:	6a 52                	push   $0x52
f0100df2:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0100df8:	50                   	push   %eax
f0100df9:	e8 9b f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dfe:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e01:	8d 83 b4 d5 fe ff    	lea    -0x12a4c(%ebx),%eax
f0100e07:	50                   	push   %eax
f0100e08:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100e0e:	50                   	push   %eax
f0100e0f:	68 91 02 00 00       	push   $0x291
f0100e14:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100e1a:	50                   	push   %eax
f0100e1b:	e8 79 f2 ff ff       	call   f0100099 <_panic>
f0100e20:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100e23:	85 ff                	test   %edi,%edi
f0100e25:	7e 1e                	jle    f0100e45 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100e27:	85 f6                	test   %esi,%esi
f0100e29:	7e 3c                	jle    f0100e67 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e2b:	83 ec 0c             	sub    $0xc,%esp
f0100e2e:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e31:	8d 83 fc d5 fe ff    	lea    -0x12a04(%ebx),%eax
f0100e37:	50                   	push   %eax
f0100e38:	e8 31 24 00 00       	call   f010326e <cprintf>
}
f0100e3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e40:	5b                   	pop    %ebx
f0100e41:	5e                   	pop    %esi
f0100e42:	5f                   	pop    %edi
f0100e43:	5d                   	pop    %ebp
f0100e44:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e45:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e48:	8d 83 74 dd fe ff    	lea    -0x1228c(%ebx),%eax
f0100e4e:	50                   	push   %eax
f0100e4f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100e55:	50                   	push   %eax
f0100e56:	68 99 02 00 00       	push   $0x299
f0100e5b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100e61:	50                   	push   %eax
f0100e62:	e8 32 f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e67:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e6a:	8d 83 86 dd fe ff    	lea    -0x1227a(%ebx),%eax
f0100e70:	50                   	push   %eax
f0100e71:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0100e77:	50                   	push   %eax
f0100e78:	68 9a 02 00 00       	push   $0x29a
f0100e7d:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0100e83:	50                   	push   %eax
f0100e84:	e8 10 f2 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100e89:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e8c:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0100e92:	85 c0                	test   %eax,%eax
f0100e94:	0f 84 2a fd ff ff    	je     f0100bc4 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e9a:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e9d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ea0:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ea3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100ea6:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ea9:	c7 c3 d0 96 11 f0    	mov    $0xf01196d0,%ebx
f0100eaf:	89 c2                	mov    %eax,%edx
f0100eb1:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100eb3:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100eb9:	0f 95 c2             	setne  %dl
f0100ebc:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ebf:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ec3:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ec5:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ec9:	8b 00                	mov    (%eax),%eax
f0100ecb:	85 c0                	test   %eax,%eax
f0100ecd:	75 e0                	jne    f0100eaf <check_page_free_list+0x322>
		*tp[1] = 0;
f0100ecf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ed2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ed8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100edb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ede:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ee0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ee3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ee6:	89 87 90 1f 00 00    	mov    %eax,0x1f90(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100eec:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ef3:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100ef6:	8b b0 90 1f 00 00    	mov    0x1f90(%eax),%esi
f0100efc:	c7 c7 d0 96 11 f0    	mov    $0xf01196d0,%edi
	if (PGNUM(pa) >= npages)
f0100f02:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0100f08:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f0b:	e9 ed fc ff ff       	jmp    f0100bfd <check_page_free_list+0x70>

f0100f10 <page_init>:
{
f0100f10:	55                   	push   %ebp
f0100f11:	89 e5                	mov    %esp,%ebp
f0100f13:	57                   	push   %edi
f0100f14:	56                   	push   %esi
f0100f15:	53                   	push   %ebx
f0100f16:	83 ec 1c             	sub    $0x1c,%esp
f0100f19:	e8 c5 22 00 00       	call   f01031e3 <__x86.get_pc_thunk.di>
f0100f1e:	81 c7 ee 63 01 00    	add    $0x163ee,%edi
f0100f24:	89 fe                	mov    %edi,%esi
f0100f26:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	pages[0].pp_ref = 1;
f0100f29:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0100f2f:	8b 00                	mov    (%eax),%eax
f0100f31:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100f37:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for (i = 1; i<npages_basemem; i++)
f0100f3d:	8b bf 94 1f 00 00    	mov    0x1f94(%edi),%edi
f0100f43:	8b 9e 90 1f 00 00    	mov    0x1f90(%esi),%ebx
f0100f49:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f4e:	b8 01 00 00 00       	mov    $0x1,%eax
		pages[i].pp_ref = 0;
f0100f53:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
	for (i = 1; i<npages_basemem; i++)
f0100f59:	eb 1f                	jmp    f0100f7a <page_init+0x6a>
		pages[i].pp_ref = 0;
f0100f5b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f62:	89 d1                	mov    %edx,%ecx
f0100f64:	03 0e                	add    (%esi),%ecx
f0100f66:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100f6c:	89 19                	mov    %ebx,(%ecx)
	for (i = 1; i<npages_basemem; i++)
f0100f6e:	83 c0 01             	add    $0x1,%eax
		page_free_list = &pages[i];
f0100f71:	89 d3                	mov    %edx,%ebx
f0100f73:	03 1e                	add    (%esi),%ebx
f0100f75:	ba 01 00 00 00       	mov    $0x1,%edx
	for (i = 1; i<npages_basemem; i++)
f0100f7a:	39 c7                	cmp    %eax,%edi
f0100f7c:	77 dd                	ja     f0100f5b <page_init+0x4b>
f0100f7e:	84 d2                	test   %dl,%dl
f0100f80:	75 38                	jne    f0100fba <page_init+0xaa>
f0100f82:	b8 00 05 00 00       	mov    $0x500,%eax
		pages[i].pp_ref = 1;
f0100f87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f8a:	c7 c1 d0 96 11 f0    	mov    $0xf01196d0,%ecx
f0100f90:	89 c2                	mov    %eax,%edx
f0100f92:	03 11                	add    (%ecx),%edx
f0100f94:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link = NULL;
f0100f9a:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0100fa0:	83 c0 08             	add    $0x8,%eax
	for (i=IOPHYSMEM/PGSIZE; i<EXTPHYSMEM/PGSIZE; i++)
f0100fa3:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100fa8:	75 e6                	jne    f0100f90 <page_init+0x80>
f0100faa:	bb 00 01 00 00       	mov    $0x100,%ebx
		pages[i].pp_ref = 1;
f0100faf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fb2:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0100fb8:	eb 1f                	jmp    f0100fd9 <page_init+0xc9>
f0100fba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fbd:	89 98 90 1f 00 00    	mov    %ebx,0x1f90(%eax)
f0100fc3:	eb bd                	jmp    f0100f82 <page_init+0x72>
f0100fc5:	8b 06                	mov    (%esi),%eax
f0100fc7:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100fca:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
		pages[i].pp_link = NULL;
f0100fd0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for (; i<PADDR(boot_alloc(0))/PGSIZE; i++)
f0100fd6:	83 c3 01             	add    $0x1,%ebx
f0100fd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fde:	e8 fe fa ff ff       	call   f0100ae1 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0100fe3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100fe8:	76 2f                	jbe    f0101019 <page_init+0x109>
	return (physaddr_t)kva - KERNBASE;
f0100fea:	05 00 00 00 10       	add    $0x10000000,%eax
f0100fef:	c1 e8 0c             	shr    $0xc,%eax
f0100ff2:	39 d8                	cmp    %ebx,%eax
f0100ff4:	77 cf                	ja     f0100fc5 <page_init+0xb5>
f0100ff6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ff9:	8b 8e 90 1f 00 00    	mov    0x1f90(%esi),%ecx
f0100fff:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0101006:	ba 00 00 00 00       	mov    $0x0,%edx
	for (; i<npages; i++)
f010100b:	c7 c7 c8 96 11 f0    	mov    $0xf01196c8,%edi
		pages[i].pp_ref = 0;
f0101011:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0101017:	eb 37                	jmp    f0101050 <page_init+0x140>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101019:	50                   	push   %eax
f010101a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010101d:	8d 83 f0 d4 fe ff    	lea    -0x12b10(%ebx),%eax
f0101023:	50                   	push   %eax
f0101024:	68 2a 01 00 00       	push   $0x12a
f0101029:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010102f:	50                   	push   %eax
f0101030:	e8 64 f0 ff ff       	call   f0100099 <_panic>
f0101035:	89 c2                	mov    %eax,%edx
f0101037:	03 16                	add    (%esi),%edx
f0101039:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f010103f:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f0101041:	89 c1                	mov    %eax,%ecx
f0101043:	03 0e                	add    (%esi),%ecx
	for (; i<npages; i++)
f0101045:	83 c3 01             	add    $0x1,%ebx
f0101048:	83 c0 08             	add    $0x8,%eax
f010104b:	ba 01 00 00 00       	mov    $0x1,%edx
f0101050:	39 1f                	cmp    %ebx,(%edi)
f0101052:	77 e1                	ja     f0101035 <page_init+0x125>
f0101054:	84 d2                	test   %dl,%dl
f0101056:	75 08                	jne    f0101060 <page_init+0x150>
}
f0101058:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010105b:	5b                   	pop    %ebx
f010105c:	5e                   	pop    %esi
f010105d:	5f                   	pop    %edi
f010105e:	5d                   	pop    %ebp
f010105f:	c3                   	ret    
f0101060:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101063:	89 88 90 1f 00 00    	mov    %ecx,0x1f90(%eax)
f0101069:	eb ed                	jmp    f0101058 <page_init+0x148>

f010106b <page_alloc>:
{
f010106b:	55                   	push   %ebp
f010106c:	89 e5                	mov    %esp,%ebp
f010106e:	56                   	push   %esi
f010106f:	53                   	push   %ebx
f0101070:	e8 da f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101075:	81 c3 97 62 01 00    	add    $0x16297,%ebx
	struct PageInfo *result = page_free_list;
f010107b:	8b b3 90 1f 00 00    	mov    0x1f90(%ebx),%esi
	if (!result)	
f0101081:	85 f6                	test   %esi,%esi
f0101083:	74 14                	je     f0101099 <page_alloc+0x2e>
		page_free_list = result->pp_link;
f0101085:	8b 06                	mov    (%esi),%eax
f0101087:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
		result->pp_link = NULL;
f010108d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if (alloc_flags & ALLOC_ZERO)
f0101093:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101097:	75 09                	jne    f01010a2 <page_alloc+0x37>
}
f0101099:	89 f0                	mov    %esi,%eax
f010109b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010109e:	5b                   	pop    %ebx
f010109f:	5e                   	pop    %esi
f01010a0:	5d                   	pop    %ebp
f01010a1:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f01010a2:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f01010a8:	89 f2                	mov    %esi,%edx
f01010aa:	2b 10                	sub    (%eax),%edx
f01010ac:	89 d0                	mov    %edx,%eax
f01010ae:	c1 f8 03             	sar    $0x3,%eax
f01010b1:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01010b4:	89 c1                	mov    %eax,%ecx
f01010b6:	c1 e9 0c             	shr    $0xc,%ecx
f01010b9:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01010bf:	3b 0a                	cmp    (%edx),%ecx
f01010c1:	73 1a                	jae    f01010dd <page_alloc+0x72>
			memset(page2kva(result),'\0',PGSIZE);
f01010c3:	83 ec 04             	sub    $0x4,%esp
f01010c6:	68 00 10 00 00       	push   $0x1000
f01010cb:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f01010cd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010d2:	50                   	push   %eax
f01010d3:	e8 df 2d 00 00       	call   f0103eb7 <memset>
f01010d8:	83 c4 10             	add    $0x10,%esp
f01010db:	eb bc                	jmp    f0101099 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010dd:	50                   	push   %eax
f01010de:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f01010e4:	50                   	push   %eax
f01010e5:	6a 52                	push   $0x52
f01010e7:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f01010ed:	50                   	push   %eax
f01010ee:	e8 a6 ef ff ff       	call   f0100099 <_panic>

f01010f3 <page_free>:
{
f01010f3:	55                   	push   %ebp
f01010f4:	89 e5                	mov    %esp,%ebp
f01010f6:	53                   	push   %ebx
f01010f7:	83 ec 04             	sub    $0x4,%esp
f01010fa:	e8 50 f0 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01010ff:	81 c3 0d 62 01 00    	add    $0x1620d,%ebx
f0101105:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref || pp->pp_link)
f0101108:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010110d:	75 18                	jne    f0101127 <page_free+0x34>
f010110f:	83 38 00             	cmpl   $0x0,(%eax)
f0101112:	75 13                	jne    f0101127 <page_free+0x34>
	pp->pp_link = page_free_list;
f0101114:	8b 8b 90 1f 00 00    	mov    0x1f90(%ebx),%ecx
f010111a:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f010111c:	89 83 90 1f 00 00    	mov    %eax,0x1f90(%ebx)
}
f0101122:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101125:	c9                   	leave  
f0101126:	c3                   	ret    
		panic("This page should not be free!(pp_ref or pp_link is not zero)\n");
f0101127:	83 ec 04             	sub    $0x4,%esp
f010112a:	8d 83 20 d6 fe ff    	lea    -0x129e0(%ebx),%eax
f0101130:	50                   	push   %eax
f0101131:	68 66 01 00 00       	push   $0x166
f0101136:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010113c:	50                   	push   %eax
f010113d:	e8 57 ef ff ff       	call   f0100099 <_panic>

f0101142 <page_decref>:
{
f0101142:	55                   	push   %ebp
f0101143:	89 e5                	mov    %esp,%ebp
f0101145:	83 ec 08             	sub    $0x8,%esp
f0101148:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010114b:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010114f:	83 e8 01             	sub    $0x1,%eax
f0101152:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101156:	66 85 c0             	test   %ax,%ax
f0101159:	74 02                	je     f010115d <page_decref+0x1b>
}
f010115b:	c9                   	leave  
f010115c:	c3                   	ret    
		page_free(pp);
f010115d:	83 ec 0c             	sub    $0xc,%esp
f0101160:	52                   	push   %edx
f0101161:	e8 8d ff ff ff       	call   f01010f3 <page_free>
f0101166:	83 c4 10             	add    $0x10,%esp
}
f0101169:	eb f0                	jmp    f010115b <page_decref+0x19>

f010116b <pgdir_walk>:
{
f010116b:	55                   	push   %ebp
f010116c:	89 e5                	mov    %esp,%ebp
f010116e:	57                   	push   %edi
f010116f:	56                   	push   %esi
f0101170:	53                   	push   %ebx
f0101171:	83 ec 0c             	sub    $0xc,%esp
f0101174:	e8 d6 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101179:	81 c3 93 61 01 00    	add    $0x16193,%ebx
f010117f:	8b 45 0c             	mov    0xc(%ebp),%eax
	uint32_t ptx=PTX(va);
f0101182:	89 c6                	mov    %eax,%esi
f0101184:	c1 ee 0c             	shr    $0xc,%esi
f0101187:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	uint32_t pdx=PDX(va);
f010118d:	c1 e8 16             	shr    $0x16,%eax
	pde_t *pde=&pgdir[pdx];
f0101190:	8d 3c 85 00 00 00 00 	lea    0x0(,%eax,4),%edi
f0101197:	03 7d 08             	add    0x8(%ebp),%edi
	if ((*pde) & PTE_P) 
f010119a:	8b 07                	mov    (%edi),%eax
f010119c:	a8 01                	test   $0x1,%al
f010119e:	74 3c                	je     f01011dc <pgdir_walk+0x71>
		pte = KADDR(PTE_ADDR(*pde));
f01011a0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01011a5:	89 c2                	mov    %eax,%edx
f01011a7:	c1 ea 0c             	shr    $0xc,%edx
f01011aa:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f01011b0:	39 11                	cmp    %edx,(%ecx)
f01011b2:	76 0f                	jbe    f01011c3 <pgdir_walk+0x58>
		return pte+ptx;
f01011b4:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
}
f01011bb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011be:	5b                   	pop    %ebx
f01011bf:	5e                   	pop    %esi
f01011c0:	5f                   	pop    %edi
f01011c1:	5d                   	pop    %ebp
f01011c2:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011c3:	50                   	push   %eax
f01011c4:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f01011ca:	50                   	push   %eax
f01011cb:	68 9e 01 00 00       	push   $0x19e
f01011d0:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01011d6:	50                   	push   %eax
f01011d7:	e8 bd ee ff ff       	call   f0100099 <_panic>
		if (!(*pde) && !create)	
f01011dc:	0b 45 10             	or     0x10(%ebp),%eax
f01011df:	74 60                	je     f0101241 <pgdir_walk+0xd6>
		new_pg = page_alloc(ALLOC_ZERO);
f01011e1:	83 ec 0c             	sub    $0xc,%esp
f01011e4:	6a 01                	push   $0x1
f01011e6:	e8 80 fe ff ff       	call   f010106b <page_alloc>
		if (!new_pg)
f01011eb:	83 c4 10             	add    $0x10,%esp
f01011ee:	85 c0                	test   %eax,%eax
f01011f0:	74 59                	je     f010124b <pgdir_walk+0xe0>
	return (pp - pages) << PGSHIFT;
f01011f2:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f01011f8:	89 c1                	mov    %eax,%ecx
f01011fa:	2b 0a                	sub    (%edx),%ecx
f01011fc:	89 ca                	mov    %ecx,%edx
f01011fe:	c1 fa 03             	sar    $0x3,%edx
f0101201:	c1 e2 0c             	shl    $0xc,%edx
		*pde =PTE_ADDR(page2pa(new_pg))|PTE_P|PTE_W|PTE_U;
f0101204:	89 d1                	mov    %edx,%ecx
f0101206:	83 c9 07             	or     $0x7,%ecx
f0101209:	89 0f                	mov    %ecx,(%edi)
	if (PGNUM(pa) >= npages)
f010120b:	89 d7                	mov    %edx,%edi
f010120d:	c1 ef 0c             	shr    $0xc,%edi
f0101210:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101216:	3b 39                	cmp    (%ecx),%edi
f0101218:	73 0e                	jae    f0101228 <pgdir_walk+0xbd>
		new_pg->pp_ref++;
f010121a:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
		return pte+ptx;
f010121f:	8d 84 b2 00 00 00 f0 	lea    -0x10000000(%edx,%esi,4),%eax
f0101226:	eb 93                	jmp    f01011bb <pgdir_walk+0x50>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101228:	52                   	push   %edx
f0101229:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f010122f:	50                   	push   %eax
f0101230:	68 b1 01 00 00       	push   $0x1b1
f0101235:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010123b:	50                   	push   %eax
f010123c:	e8 58 ee ff ff       	call   f0100099 <_panic>
			return NULL;
f0101241:	b8 00 00 00 00       	mov    $0x0,%eax
f0101246:	e9 70 ff ff ff       	jmp    f01011bb <pgdir_walk+0x50>
			return NULL;
f010124b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101250:	e9 66 ff ff ff       	jmp    f01011bb <pgdir_walk+0x50>

f0101255 <boot_map_region>:
{
f0101255:	55                   	push   %ebp
f0101256:	89 e5                	mov    %esp,%ebp
f0101258:	57                   	push   %edi
f0101259:	56                   	push   %esi
f010125a:	53                   	push   %ebx
f010125b:	83 ec 1c             	sub    $0x1c,%esp
f010125e:	e8 80 1f 00 00       	call   f01031e3 <__x86.get_pc_thunk.di>
f0101263:	81 c7 a9 60 01 00    	add    $0x160a9,%edi
f0101269:	89 7d d8             	mov    %edi,-0x28(%ebp)
f010126c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010126f:	8b 45 08             	mov    0x8(%ebp),%eax
	int page_num = ROUNDUP(size,PGSIZE)/PGSIZE;
f0101272:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0101278:	c1 e9 0c             	shr    $0xc,%ecx
f010127b:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	now_pa = pa;
f010127e:	89 c3                	mov    %eax,%ebx
	for (int i=0; i<page_num; i++)
f0101280:	be 00 00 00 00       	mov    $0x0,%esi
		pte = pgdir_walk(pgdir,(void*)now_va,true);
f0101285:	89 d7                	mov    %edx,%edi
f0101287:	29 c7                	sub    %eax,%edi
		*pte = PTE_ADDR(now_pa) | perm | PTE_P;
f0101289:	8b 45 0c             	mov    0xc(%ebp),%eax
f010128c:	83 c8 01             	or     $0x1,%eax
f010128f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for (int i=0; i<page_num; i++)
f0101292:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101295:	7d 4e                	jge    f01012e5 <boot_map_region+0x90>
		pte = pgdir_walk(pgdir,(void*)now_va,true);
f0101297:	83 ec 04             	sub    $0x4,%esp
f010129a:	6a 01                	push   $0x1
f010129c:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f010129f:	50                   	push   %eax
f01012a0:	ff 75 e0             	pushl  -0x20(%ebp)
f01012a3:	e8 c3 fe ff ff       	call   f010116b <pgdir_walk>
		if (!pte)
f01012a8:	83 c4 10             	add    $0x10,%esp
f01012ab:	85 c0                	test   %eax,%eax
f01012ad:	74 18                	je     f01012c7 <boot_map_region+0x72>
		*pte = PTE_ADDR(now_pa) | perm | PTE_P;
f01012af:	89 da                	mov    %ebx,%edx
f01012b1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01012b7:	0b 55 dc             	or     -0x24(%ebp),%edx
f01012ba:	89 10                	mov    %edx,(%eax)
		now_pa += PGSIZE;
f01012bc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (int i=0; i<page_num; i++)
f01012c2:	83 c6 01             	add    $0x1,%esi
f01012c5:	eb cb                	jmp    f0101292 <boot_map_region+0x3d>
			panic("in function boot_map_region:pte is null\n");
f01012c7:	83 ec 04             	sub    $0x4,%esp
f01012ca:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01012cd:	8d 83 60 d6 fe ff    	lea    -0x129a0(%ebx),%eax
f01012d3:	50                   	push   %eax
f01012d4:	68 da 01 00 00       	push   $0x1da
f01012d9:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01012df:	50                   	push   %eax
f01012e0:	e8 b4 ed ff ff       	call   f0100099 <_panic>
}
f01012e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012e8:	5b                   	pop    %ebx
f01012e9:	5e                   	pop    %esi
f01012ea:	5f                   	pop    %edi
f01012eb:	5d                   	pop    %ebp
f01012ec:	c3                   	ret    

f01012ed <page_lookup>:
{
f01012ed:	55                   	push   %ebp
f01012ee:	89 e5                	mov    %esp,%ebp
f01012f0:	53                   	push   %ebx
f01012f1:	83 ec 08             	sub    $0x8,%esp
f01012f4:	e8 56 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01012f9:	81 c3 13 60 01 00    	add    $0x16013,%ebx
	pte_t *pte=pgdir_walk(pgdir,va,false);
f01012ff:	6a 00                	push   $0x0
f0101301:	ff 75 0c             	pushl  0xc(%ebp)
f0101304:	ff 75 08             	pushl  0x8(%ebp)
f0101307:	e8 5f fe ff ff       	call   f010116b <pgdir_walk>
	if (!pte)
f010130c:	83 c4 10             	add    $0x10,%esp
f010130f:	85 c0                	test   %eax,%eax
f0101311:	74 37                	je     f010134a <page_lookup+0x5d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101313:	8b 00                	mov    (%eax),%eax
f0101315:	c1 e8 0c             	shr    $0xc,%eax
f0101318:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010131e:	3b 02                	cmp    (%edx),%eax
f0101320:	73 10                	jae    f0101332 <page_lookup+0x45>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101322:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101328:	8b 12                	mov    (%edx),%edx
f010132a:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010132d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101330:	c9                   	leave  
f0101331:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101332:	83 ec 04             	sub    $0x4,%esp
f0101335:	8d 83 8c d6 fe ff    	lea    -0x12974(%ebx),%eax
f010133b:	50                   	push   %eax
f010133c:	6a 4b                	push   $0x4b
f010133e:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0101344:	50                   	push   %eax
f0101345:	e8 4f ed ff ff       	call   f0100099 <_panic>
		return NULL;
f010134a:	b8 00 00 00 00       	mov    $0x0,%eax
f010134f:	eb dc                	jmp    f010132d <page_lookup+0x40>

f0101351 <page_remove>:
{
f0101351:	55                   	push   %ebp
f0101352:	89 e5                	mov    %esp,%ebp
f0101354:	56                   	push   %esi
f0101355:	53                   	push   %ebx
f0101356:	e8 f4 ed ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010135b:	81 c3 b1 5f 01 00    	add    $0x15fb1,%ebx
f0101361:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir,va,false);
f0101364:	83 ec 04             	sub    $0x4,%esp
f0101367:	6a 00                	push   $0x0
f0101369:	56                   	push   %esi
f010136a:	ff 75 08             	pushl  0x8(%ebp)
f010136d:	e8 f9 fd ff ff       	call   f010116b <pgdir_walk>
	if (!(*pte))
f0101372:	8b 10                	mov    (%eax),%edx
f0101374:	83 c4 10             	add    $0x10,%esp
f0101377:	85 d2                	test   %edx,%edx
f0101379:	75 07                	jne    f0101382 <page_remove+0x31>
}
f010137b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010137e:	5b                   	pop    %ebx
f010137f:	5e                   	pop    %esi
f0101380:	5d                   	pop    %ebp
f0101381:	c3                   	ret    
	if (PGNUM(pa) >= npages)
f0101382:	c1 ea 0c             	shr    $0xc,%edx
f0101385:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f010138b:	3b 11                	cmp    (%ecx),%edx
f010138d:	73 22                	jae    f01013b1 <page_remove+0x60>
	return &pages[PGNUM(pa)];
f010138f:	c7 c1 d0 96 11 f0    	mov    $0xf01196d0,%ecx
f0101395:	8b 09                	mov    (%ecx),%ecx
f0101397:	8d 14 d1             	lea    (%ecx,%edx,8),%edx
	*pte = 0;
f010139a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01013a0:	0f 01 3e             	invlpg (%esi)
	page_decref(pg);
f01013a3:	83 ec 0c             	sub    $0xc,%esp
f01013a6:	52                   	push   %edx
f01013a7:	e8 96 fd ff ff       	call   f0101142 <page_decref>
f01013ac:	83 c4 10             	add    $0x10,%esp
f01013af:	eb ca                	jmp    f010137b <page_remove+0x2a>
		panic("pa2page called with invalid pa");
f01013b1:	83 ec 04             	sub    $0x4,%esp
f01013b4:	8d 83 8c d6 fe ff    	lea    -0x12974(%ebx),%eax
f01013ba:	50                   	push   %eax
f01013bb:	6a 4b                	push   $0x4b
f01013bd:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f01013c3:	50                   	push   %eax
f01013c4:	e8 d0 ec ff ff       	call   f0100099 <_panic>

f01013c9 <page_insert>:
{
f01013c9:	55                   	push   %ebp
f01013ca:	89 e5                	mov    %esp,%ebp
f01013cc:	57                   	push   %edi
f01013cd:	56                   	push   %esi
f01013ce:	53                   	push   %ebx
f01013cf:	83 ec 10             	sub    $0x10,%esp
f01013d2:	e8 0c 1e 00 00       	call   f01031e3 <__x86.get_pc_thunk.di>
f01013d7:	81 c7 35 5f 01 00    	add    $0x15f35,%edi
f01013dd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte = pgdir_walk(pgdir,va,true);
f01013e0:	6a 01                	push   $0x1
f01013e2:	ff 75 10             	pushl  0x10(%ebp)
f01013e5:	ff 75 08             	pushl  0x8(%ebp)
f01013e8:	e8 7e fd ff ff       	call   f010116b <pgdir_walk>
	if (!pte)
f01013ed:	83 c4 10             	add    $0x10,%esp
f01013f0:	85 c0                	test   %eax,%eax
f01013f2:	74 65                	je     f0101459 <page_insert+0x90>
f01013f4:	89 c6                	mov    %eax,%esi
	if (*pte & PTE_P)
f01013f6:	8b 00                	mov    (%eax),%eax
f01013f8:	a8 01                	test   $0x1,%al
f01013fa:	74 20                	je     f010141c <page_insert+0x53>
		if (PTE_ADDR(*pte) == page2pa(pp))
f01013fc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	return (pp - pages) << PGSHIFT;
f0101401:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101407:	89 d9                	mov    %ebx,%ecx
f0101409:	2b 0a                	sub    (%edx),%ecx
f010140b:	89 ca                	mov    %ecx,%edx
f010140d:	c1 fa 03             	sar    $0x3,%edx
f0101410:	c1 e2 0c             	shl    $0xc,%edx
f0101413:	39 d0                	cmp    %edx,%eax
f0101415:	75 2f                	jne    f0101446 <page_insert+0x7d>
			pp->pp_ref--;
f0101417:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
	pp->pp_ref++;
f010141c:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
f0101421:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101427:	2b 18                	sub    (%eax),%ebx
f0101429:	c1 fb 03             	sar    $0x3,%ebx
f010142c:	c1 e3 0c             	shl    $0xc,%ebx
	*pte = page2pa(pp)|perm|PTE_P;
f010142f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101432:	83 c8 01             	or     $0x1,%eax
f0101435:	09 c3                	or     %eax,%ebx
f0101437:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0101439:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010143e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101441:	5b                   	pop    %ebx
f0101442:	5e                   	pop    %esi
f0101443:	5f                   	pop    %edi
f0101444:	5d                   	pop    %ebp
f0101445:	c3                   	ret    
			page_remove(pgdir,va);
f0101446:	83 ec 08             	sub    $0x8,%esp
f0101449:	ff 75 10             	pushl  0x10(%ebp)
f010144c:	ff 75 08             	pushl  0x8(%ebp)
f010144f:	e8 fd fe ff ff       	call   f0101351 <page_remove>
f0101454:	83 c4 10             	add    $0x10,%esp
f0101457:	eb c3                	jmp    f010141c <page_insert+0x53>
		return -E_NO_MEM;
f0101459:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010145e:	eb de                	jmp    f010143e <page_insert+0x75>

f0101460 <mem_init>:
{
f0101460:	55                   	push   %ebp
f0101461:	89 e5                	mov    %esp,%ebp
f0101463:	57                   	push   %edi
f0101464:	56                   	push   %esi
f0101465:	53                   	push   %ebx
f0101466:	83 ec 3c             	sub    $0x3c,%esp
f0101469:	e8 83 f2 ff ff       	call   f01006f1 <__x86.get_pc_thunk.ax>
f010146e:	05 9e 5e 01 00       	add    $0x15e9e,%eax
f0101473:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f0101476:	b8 15 00 00 00       	mov    $0x15,%eax
f010147b:	e8 ae f5 ff ff       	call   f0100a2e <nvram_read>
f0101480:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101482:	b8 17 00 00 00       	mov    $0x17,%eax
f0101487:	e8 a2 f5 ff ff       	call   f0100a2e <nvram_read>
f010148c:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010148e:	b8 34 00 00 00       	mov    $0x34,%eax
f0101493:	e8 96 f5 ff ff       	call   f0100a2e <nvram_read>
f0101498:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f010149b:	85 c0                	test   %eax,%eax
f010149d:	0f 85 cd 00 00 00    	jne    f0101570 <mem_init+0x110>
		totalmem = 1 * 1024 + extmem;
f01014a3:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01014a9:	85 f6                	test   %esi,%esi
f01014ab:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01014ae:	89 c1                	mov    %eax,%ecx
f01014b0:	c1 e9 02             	shr    $0x2,%ecx
f01014b3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01014b6:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f01014bc:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01014be:	89 da                	mov    %ebx,%edx
f01014c0:	c1 ea 02             	shr    $0x2,%edx
f01014c3:	89 97 94 1f 00 00    	mov    %edx,0x1f94(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014c9:	89 c2                	mov    %eax,%edx
f01014cb:	29 da                	sub    %ebx,%edx
f01014cd:	52                   	push   %edx
f01014ce:	53                   	push   %ebx
f01014cf:	50                   	push   %eax
f01014d0:	8d 87 ac d6 fe ff    	lea    -0x12954(%edi),%eax
f01014d6:	50                   	push   %eax
f01014d7:	89 fb                	mov    %edi,%ebx
f01014d9:	e8 90 1d 00 00       	call   f010326e <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01014de:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014e3:	e8 f9 f5 ff ff       	call   f0100ae1 <boot_alloc>
f01014e8:	c7 c6 cc 96 11 f0    	mov    $0xf01196cc,%esi
f01014ee:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01014f0:	83 c4 0c             	add    $0xc,%esp
f01014f3:	68 00 10 00 00       	push   $0x1000
f01014f8:	6a 00                	push   $0x0
f01014fa:	50                   	push   %eax
f01014fb:	e8 b7 29 00 00       	call   f0103eb7 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101500:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101502:	83 c4 10             	add    $0x10,%esp
f0101505:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010150a:	76 6e                	jbe    f010157a <mem_init+0x11a>
	return (physaddr_t)kva - KERNBASE;
f010150c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101512:	83 ca 05             	or     $0x5,%edx
f0101515:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f010151b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010151e:	c7 c3 c8 96 11 f0    	mov    $0xf01196c8,%ebx
f0101524:	8b 03                	mov    (%ebx),%eax
f0101526:	c1 e0 03             	shl    $0x3,%eax
f0101529:	e8 b3 f5 ff ff       	call   f0100ae1 <boot_alloc>
f010152e:	c7 c6 d0 96 11 f0    	mov    $0xf01196d0,%esi
f0101534:	89 06                	mov    %eax,(%esi)
	memset(pages,0,npages*sizeof(struct PageInfo));
f0101536:	83 ec 04             	sub    $0x4,%esp
f0101539:	8b 13                	mov    (%ebx),%edx
f010153b:	c1 e2 03             	shl    $0x3,%edx
f010153e:	52                   	push   %edx
f010153f:	6a 00                	push   $0x0
f0101541:	50                   	push   %eax
f0101542:	89 fb                	mov    %edi,%ebx
f0101544:	e8 6e 29 00 00       	call   f0103eb7 <memset>
	page_init();
f0101549:	e8 c2 f9 ff ff       	call   f0100f10 <page_init>
	check_page_free_list(1);
f010154e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101553:	e8 35 f6 ff ff       	call   f0100b8d <check_page_free_list>
	if (!pages)
f0101558:	83 c4 10             	add    $0x10,%esp
f010155b:	83 3e 00             	cmpl   $0x0,(%esi)
f010155e:	74 36                	je     f0101596 <mem_init+0x136>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101560:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101563:	8b 80 90 1f 00 00    	mov    0x1f90(%eax),%eax
f0101569:	be 00 00 00 00       	mov    $0x0,%esi
f010156e:	eb 49                	jmp    f01015b9 <mem_init+0x159>
		totalmem = 16 * 1024 + ext16mem;
f0101570:	05 00 40 00 00       	add    $0x4000,%eax
f0101575:	e9 34 ff ff ff       	jmp    f01014ae <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010157a:	50                   	push   %eax
f010157b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010157e:	8d 83 f0 d4 fe ff    	lea    -0x12b10(%ebx),%eax
f0101584:	50                   	push   %eax
f0101585:	68 97 00 00 00       	push   $0x97
f010158a:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0101590:	50                   	push   %eax
f0101591:	e8 03 eb ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101596:	83 ec 04             	sub    $0x4,%esp
f0101599:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010159c:	8d 83 97 dd fe ff    	lea    -0x12269(%ebx),%eax
f01015a2:	50                   	push   %eax
f01015a3:	68 ad 02 00 00       	push   $0x2ad
f01015a8:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01015ae:	50                   	push   %eax
f01015af:	e8 e5 ea ff ff       	call   f0100099 <_panic>
		++nfree;
f01015b4:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015b7:	8b 00                	mov    (%eax),%eax
f01015b9:	85 c0                	test   %eax,%eax
f01015bb:	75 f7                	jne    f01015b4 <mem_init+0x154>
	assert((pp0 = page_alloc(0)));
f01015bd:	83 ec 0c             	sub    $0xc,%esp
f01015c0:	6a 00                	push   $0x0
f01015c2:	e8 a4 fa ff ff       	call   f010106b <page_alloc>
f01015c7:	89 c3                	mov    %eax,%ebx
f01015c9:	83 c4 10             	add    $0x10,%esp
f01015cc:	85 c0                	test   %eax,%eax
f01015ce:	0f 84 3b 02 00 00    	je     f010180f <mem_init+0x3af>
	assert((pp1 = page_alloc(0)));
f01015d4:	83 ec 0c             	sub    $0xc,%esp
f01015d7:	6a 00                	push   $0x0
f01015d9:	e8 8d fa ff ff       	call   f010106b <page_alloc>
f01015de:	89 c7                	mov    %eax,%edi
f01015e0:	83 c4 10             	add    $0x10,%esp
f01015e3:	85 c0                	test   %eax,%eax
f01015e5:	0f 84 46 02 00 00    	je     f0101831 <mem_init+0x3d1>
	assert((pp2 = page_alloc(0)));
f01015eb:	83 ec 0c             	sub    $0xc,%esp
f01015ee:	6a 00                	push   $0x0
f01015f0:	e8 76 fa ff ff       	call   f010106b <page_alloc>
f01015f5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01015f8:	83 c4 10             	add    $0x10,%esp
f01015fb:	85 c0                	test   %eax,%eax
f01015fd:	0f 84 50 02 00 00    	je     f0101853 <mem_init+0x3f3>
	assert(pp1 && pp1 != pp0);
f0101603:	39 fb                	cmp    %edi,%ebx
f0101605:	0f 84 6a 02 00 00    	je     f0101875 <mem_init+0x415>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010160b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010160e:	39 c7                	cmp    %eax,%edi
f0101610:	0f 84 81 02 00 00    	je     f0101897 <mem_init+0x437>
f0101616:	39 c3                	cmp    %eax,%ebx
f0101618:	0f 84 79 02 00 00    	je     f0101897 <mem_init+0x437>
	return (pp - pages) << PGSHIFT;
f010161e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101621:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101627:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101629:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f010162f:	8b 10                	mov    (%eax),%edx
f0101631:	c1 e2 0c             	shl    $0xc,%edx
f0101634:	89 d8                	mov    %ebx,%eax
f0101636:	29 c8                	sub    %ecx,%eax
f0101638:	c1 f8 03             	sar    $0x3,%eax
f010163b:	c1 e0 0c             	shl    $0xc,%eax
f010163e:	39 d0                	cmp    %edx,%eax
f0101640:	0f 83 73 02 00 00    	jae    f01018b9 <mem_init+0x459>
f0101646:	89 f8                	mov    %edi,%eax
f0101648:	29 c8                	sub    %ecx,%eax
f010164a:	c1 f8 03             	sar    $0x3,%eax
f010164d:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101650:	39 c2                	cmp    %eax,%edx
f0101652:	0f 86 83 02 00 00    	jbe    f01018db <mem_init+0x47b>
f0101658:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010165b:	29 c8                	sub    %ecx,%eax
f010165d:	c1 f8 03             	sar    $0x3,%eax
f0101660:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101663:	39 c2                	cmp    %eax,%edx
f0101665:	0f 86 92 02 00 00    	jbe    f01018fd <mem_init+0x49d>
	fl = page_free_list;
f010166b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010166e:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f0101674:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101677:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f010167e:	00 00 00 
	assert(!page_alloc(0));
f0101681:	83 ec 0c             	sub    $0xc,%esp
f0101684:	6a 00                	push   $0x0
f0101686:	e8 e0 f9 ff ff       	call   f010106b <page_alloc>
f010168b:	83 c4 10             	add    $0x10,%esp
f010168e:	85 c0                	test   %eax,%eax
f0101690:	0f 85 89 02 00 00    	jne    f010191f <mem_init+0x4bf>
	page_free(pp0);
f0101696:	83 ec 0c             	sub    $0xc,%esp
f0101699:	53                   	push   %ebx
f010169a:	e8 54 fa ff ff       	call   f01010f3 <page_free>
	page_free(pp1);
f010169f:	89 3c 24             	mov    %edi,(%esp)
f01016a2:	e8 4c fa ff ff       	call   f01010f3 <page_free>
	page_free(pp2);
f01016a7:	83 c4 04             	add    $0x4,%esp
f01016aa:	ff 75 d0             	pushl  -0x30(%ebp)
f01016ad:	e8 41 fa ff ff       	call   f01010f3 <page_free>
	assert((pp0 = page_alloc(0)));
f01016b2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016b9:	e8 ad f9 ff ff       	call   f010106b <page_alloc>
f01016be:	89 c7                	mov    %eax,%edi
f01016c0:	83 c4 10             	add    $0x10,%esp
f01016c3:	85 c0                	test   %eax,%eax
f01016c5:	0f 84 76 02 00 00    	je     f0101941 <mem_init+0x4e1>
	assert((pp1 = page_alloc(0)));
f01016cb:	83 ec 0c             	sub    $0xc,%esp
f01016ce:	6a 00                	push   $0x0
f01016d0:	e8 96 f9 ff ff       	call   f010106b <page_alloc>
f01016d5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01016d8:	83 c4 10             	add    $0x10,%esp
f01016db:	85 c0                	test   %eax,%eax
f01016dd:	0f 84 80 02 00 00    	je     f0101963 <mem_init+0x503>
	assert((pp2 = page_alloc(0)));
f01016e3:	83 ec 0c             	sub    $0xc,%esp
f01016e6:	6a 00                	push   $0x0
f01016e8:	e8 7e f9 ff ff       	call   f010106b <page_alloc>
f01016ed:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016f0:	83 c4 10             	add    $0x10,%esp
f01016f3:	85 c0                	test   %eax,%eax
f01016f5:	0f 84 8a 02 00 00    	je     f0101985 <mem_init+0x525>
	assert(pp1 && pp1 != pp0);
f01016fb:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f01016fe:	0f 84 a3 02 00 00    	je     f01019a7 <mem_init+0x547>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101704:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101707:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010170a:	0f 84 b9 02 00 00    	je     f01019c9 <mem_init+0x569>
f0101710:	39 c7                	cmp    %eax,%edi
f0101712:	0f 84 b1 02 00 00    	je     f01019c9 <mem_init+0x569>
	assert(!page_alloc(0));
f0101718:	83 ec 0c             	sub    $0xc,%esp
f010171b:	6a 00                	push   $0x0
f010171d:	e8 49 f9 ff ff       	call   f010106b <page_alloc>
f0101722:	83 c4 10             	add    $0x10,%esp
f0101725:	85 c0                	test   %eax,%eax
f0101727:	0f 85 be 02 00 00    	jne    f01019eb <mem_init+0x58b>
f010172d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101730:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101736:	89 f9                	mov    %edi,%ecx
f0101738:	2b 08                	sub    (%eax),%ecx
f010173a:	89 c8                	mov    %ecx,%eax
f010173c:	c1 f8 03             	sar    $0x3,%eax
f010173f:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101742:	89 c1                	mov    %eax,%ecx
f0101744:	c1 e9 0c             	shr    $0xc,%ecx
f0101747:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f010174d:	3b 0a                	cmp    (%edx),%ecx
f010174f:	0f 83 b8 02 00 00    	jae    f0101a0d <mem_init+0x5ad>
	memset(page2kva(pp0), 1, PGSIZE);
f0101755:	83 ec 04             	sub    $0x4,%esp
f0101758:	68 00 10 00 00       	push   $0x1000
f010175d:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010175f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101764:	50                   	push   %eax
f0101765:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101768:	e8 4a 27 00 00       	call   f0103eb7 <memset>
	page_free(pp0);
f010176d:	89 3c 24             	mov    %edi,(%esp)
f0101770:	e8 7e f9 ff ff       	call   f01010f3 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101775:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010177c:	e8 ea f8 ff ff       	call   f010106b <page_alloc>
f0101781:	83 c4 10             	add    $0x10,%esp
f0101784:	85 c0                	test   %eax,%eax
f0101786:	0f 84 97 02 00 00    	je     f0101a23 <mem_init+0x5c3>
	assert(pp && pp0 == pp);
f010178c:	39 c7                	cmp    %eax,%edi
f010178e:	0f 85 b1 02 00 00    	jne    f0101a45 <mem_init+0x5e5>
	return (pp - pages) << PGSHIFT;
f0101794:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101797:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010179d:	89 fa                	mov    %edi,%edx
f010179f:	2b 10                	sub    (%eax),%edx
f01017a1:	c1 fa 03             	sar    $0x3,%edx
f01017a4:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01017a7:	89 d1                	mov    %edx,%ecx
f01017a9:	c1 e9 0c             	shr    $0xc,%ecx
f01017ac:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01017b2:	3b 08                	cmp    (%eax),%ecx
f01017b4:	0f 83 ad 02 00 00    	jae    f0101a67 <mem_init+0x607>
	return (void *)(pa + KERNBASE);
f01017ba:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01017c0:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01017c6:	80 38 00             	cmpb   $0x0,(%eax)
f01017c9:	0f 85 ae 02 00 00    	jne    f0101a7d <mem_init+0x61d>
f01017cf:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01017d2:	39 d0                	cmp    %edx,%eax
f01017d4:	75 f0                	jne    f01017c6 <mem_init+0x366>
	page_free_list = fl;
f01017d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017d9:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01017dc:	89 8b 90 1f 00 00    	mov    %ecx,0x1f90(%ebx)
	page_free(pp0);
f01017e2:	83 ec 0c             	sub    $0xc,%esp
f01017e5:	57                   	push   %edi
f01017e6:	e8 08 f9 ff ff       	call   f01010f3 <page_free>
	page_free(pp1);
f01017eb:	83 c4 04             	add    $0x4,%esp
f01017ee:	ff 75 d0             	pushl  -0x30(%ebp)
f01017f1:	e8 fd f8 ff ff       	call   f01010f3 <page_free>
	page_free(pp2);
f01017f6:	83 c4 04             	add    $0x4,%esp
f01017f9:	ff 75 cc             	pushl  -0x34(%ebp)
f01017fc:	e8 f2 f8 ff ff       	call   f01010f3 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101801:	8b 83 90 1f 00 00    	mov    0x1f90(%ebx),%eax
f0101807:	83 c4 10             	add    $0x10,%esp
f010180a:	e9 95 02 00 00       	jmp    f0101aa4 <mem_init+0x644>
	assert((pp0 = page_alloc(0)));
f010180f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101812:	8d 83 b2 dd fe ff    	lea    -0x1224e(%ebx),%eax
f0101818:	50                   	push   %eax
f0101819:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010181f:	50                   	push   %eax
f0101820:	68 b5 02 00 00       	push   $0x2b5
f0101825:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010182b:	50                   	push   %eax
f010182c:	e8 68 e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101831:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101834:	8d 83 c8 dd fe ff    	lea    -0x12238(%ebx),%eax
f010183a:	50                   	push   %eax
f010183b:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101841:	50                   	push   %eax
f0101842:	68 b6 02 00 00       	push   $0x2b6
f0101847:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010184d:	50                   	push   %eax
f010184e:	e8 46 e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101853:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101856:	8d 83 de dd fe ff    	lea    -0x12222(%ebx),%eax
f010185c:	50                   	push   %eax
f010185d:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101863:	50                   	push   %eax
f0101864:	68 b7 02 00 00       	push   $0x2b7
f0101869:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010186f:	50                   	push   %eax
f0101870:	e8 24 e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0101875:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101878:	8d 83 f4 dd fe ff    	lea    -0x1220c(%ebx),%eax
f010187e:	50                   	push   %eax
f010187f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101885:	50                   	push   %eax
f0101886:	68 ba 02 00 00       	push   $0x2ba
f010188b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0101891:	50                   	push   %eax
f0101892:	e8 02 e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101897:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010189a:	8d 83 e8 d6 fe ff    	lea    -0x12918(%ebx),%eax
f01018a0:	50                   	push   %eax
f01018a1:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01018a7:	50                   	push   %eax
f01018a8:	68 bb 02 00 00       	push   $0x2bb
f01018ad:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01018b3:	50                   	push   %eax
f01018b4:	e8 e0 e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01018b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018bc:	8d 83 06 de fe ff    	lea    -0x121fa(%ebx),%eax
f01018c2:	50                   	push   %eax
f01018c3:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01018c9:	50                   	push   %eax
f01018ca:	68 bc 02 00 00       	push   $0x2bc
f01018cf:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01018d5:	50                   	push   %eax
f01018d6:	e8 be e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01018db:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018de:	8d 83 23 de fe ff    	lea    -0x121dd(%ebx),%eax
f01018e4:	50                   	push   %eax
f01018e5:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01018eb:	50                   	push   %eax
f01018ec:	68 bd 02 00 00       	push   $0x2bd
f01018f1:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01018f7:	50                   	push   %eax
f01018f8:	e8 9c e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01018fd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101900:	8d 83 40 de fe ff    	lea    -0x121c0(%ebx),%eax
f0101906:	50                   	push   %eax
f0101907:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010190d:	50                   	push   %eax
f010190e:	68 be 02 00 00       	push   $0x2be
f0101913:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0101919:	50                   	push   %eax
f010191a:	e8 7a e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010191f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101922:	8d 83 5d de fe ff    	lea    -0x121a3(%ebx),%eax
f0101928:	50                   	push   %eax
f0101929:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010192f:	50                   	push   %eax
f0101930:	68 c5 02 00 00       	push   $0x2c5
f0101935:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010193b:	50                   	push   %eax
f010193c:	e8 58 e7 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101941:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101944:	8d 83 b2 dd fe ff    	lea    -0x1224e(%ebx),%eax
f010194a:	50                   	push   %eax
f010194b:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101951:	50                   	push   %eax
f0101952:	68 cc 02 00 00       	push   $0x2cc
f0101957:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010195d:	50                   	push   %eax
f010195e:	e8 36 e7 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101963:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101966:	8d 83 c8 dd fe ff    	lea    -0x12238(%ebx),%eax
f010196c:	50                   	push   %eax
f010196d:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101973:	50                   	push   %eax
f0101974:	68 cd 02 00 00       	push   $0x2cd
f0101979:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010197f:	50                   	push   %eax
f0101980:	e8 14 e7 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0101985:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101988:	8d 83 de dd fe ff    	lea    -0x12222(%ebx),%eax
f010198e:	50                   	push   %eax
f010198f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101995:	50                   	push   %eax
f0101996:	68 ce 02 00 00       	push   $0x2ce
f010199b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01019a1:	50                   	push   %eax
f01019a2:	e8 f2 e6 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01019a7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019aa:	8d 83 f4 dd fe ff    	lea    -0x1220c(%ebx),%eax
f01019b0:	50                   	push   %eax
f01019b1:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01019b7:	50                   	push   %eax
f01019b8:	68 d0 02 00 00       	push   $0x2d0
f01019bd:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01019c3:	50                   	push   %eax
f01019c4:	e8 d0 e6 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019c9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019cc:	8d 83 e8 d6 fe ff    	lea    -0x12918(%ebx),%eax
f01019d2:	50                   	push   %eax
f01019d3:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01019d9:	50                   	push   %eax
f01019da:	68 d1 02 00 00       	push   $0x2d1
f01019df:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01019e5:	50                   	push   %eax
f01019e6:	e8 ae e6 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01019eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019ee:	8d 83 5d de fe ff    	lea    -0x121a3(%ebx),%eax
f01019f4:	50                   	push   %eax
f01019f5:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01019fb:	50                   	push   %eax
f01019fc:	68 d2 02 00 00       	push   $0x2d2
f0101a01:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0101a07:	50                   	push   %eax
f0101a08:	e8 8c e6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a0d:	50                   	push   %eax
f0101a0e:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0101a14:	50                   	push   %eax
f0101a15:	6a 52                	push   $0x52
f0101a17:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0101a1d:	50                   	push   %eax
f0101a1e:	e8 76 e6 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a23:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a26:	8d 83 6c de fe ff    	lea    -0x12194(%ebx),%eax
f0101a2c:	50                   	push   %eax
f0101a2d:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101a33:	50                   	push   %eax
f0101a34:	68 d7 02 00 00       	push   $0x2d7
f0101a39:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0101a3f:	50                   	push   %eax
f0101a40:	e8 54 e6 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101a45:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a48:	8d 83 8a de fe ff    	lea    -0x12176(%ebx),%eax
f0101a4e:	50                   	push   %eax
f0101a4f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101a55:	50                   	push   %eax
f0101a56:	68 d8 02 00 00       	push   $0x2d8
f0101a5b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0101a61:	50                   	push   %eax
f0101a62:	e8 32 e6 ff ff       	call   f0100099 <_panic>
f0101a67:	52                   	push   %edx
f0101a68:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0101a6e:	50                   	push   %eax
f0101a6f:	6a 52                	push   $0x52
f0101a71:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0101a77:	50                   	push   %eax
f0101a78:	e8 1c e6 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101a7d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a80:	8d 83 9a de fe ff    	lea    -0x12166(%ebx),%eax
f0101a86:	50                   	push   %eax
f0101a87:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0101a8d:	50                   	push   %eax
f0101a8e:	68 db 02 00 00       	push   $0x2db
f0101a93:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0101a99:	50                   	push   %eax
f0101a9a:	e8 fa e5 ff ff       	call   f0100099 <_panic>
		--nfree;
f0101a9f:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101aa2:	8b 00                	mov    (%eax),%eax
f0101aa4:	85 c0                	test   %eax,%eax
f0101aa6:	75 f7                	jne    f0101a9f <mem_init+0x63f>
	assert(nfree == 0);
f0101aa8:	85 f6                	test   %esi,%esi
f0101aaa:	0f 85 81 08 00 00    	jne    f0102331 <mem_init+0xed1>
	cprintf("check_page_alloc() succeeded!\n");
f0101ab0:	83 ec 0c             	sub    $0xc,%esp
f0101ab3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ab6:	8d 83 08 d7 fe ff    	lea    -0x128f8(%ebx),%eax
f0101abc:	50                   	push   %eax
f0101abd:	e8 ac 17 00 00       	call   f010326e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101ac2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ac9:	e8 9d f5 ff ff       	call   f010106b <page_alloc>
f0101ace:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ad1:	83 c4 10             	add    $0x10,%esp
f0101ad4:	85 c0                	test   %eax,%eax
f0101ad6:	0f 84 77 08 00 00    	je     f0102353 <mem_init+0xef3>
	assert((pp1 = page_alloc(0)));
f0101adc:	83 ec 0c             	sub    $0xc,%esp
f0101adf:	6a 00                	push   $0x0
f0101ae1:	e8 85 f5 ff ff       	call   f010106b <page_alloc>
f0101ae6:	89 c7                	mov    %eax,%edi
f0101ae8:	83 c4 10             	add    $0x10,%esp
f0101aeb:	85 c0                	test   %eax,%eax
f0101aed:	0f 84 82 08 00 00    	je     f0102375 <mem_init+0xf15>
	assert((pp2 = page_alloc(0)));
f0101af3:	83 ec 0c             	sub    $0xc,%esp
f0101af6:	6a 00                	push   $0x0
f0101af8:	e8 6e f5 ff ff       	call   f010106b <page_alloc>
f0101afd:	89 c6                	mov    %eax,%esi
f0101aff:	83 c4 10             	add    $0x10,%esp
f0101b02:	85 c0                	test   %eax,%eax
f0101b04:	0f 84 8d 08 00 00    	je     f0102397 <mem_init+0xf37>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b0a:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101b0d:	0f 84 a6 08 00 00    	je     f01023b9 <mem_init+0xf59>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b13:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101b16:	0f 84 bf 08 00 00    	je     f01023db <mem_init+0xf7b>
f0101b1c:	39 c7                	cmp    %eax,%edi
f0101b1e:	0f 84 b7 08 00 00    	je     f01023db <mem_init+0xf7b>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b24:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b27:	8b 88 90 1f 00 00    	mov    0x1f90(%eax),%ecx
f0101b2d:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101b30:	c7 80 90 1f 00 00 00 	movl   $0x0,0x1f90(%eax)
f0101b37:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b3a:	83 ec 0c             	sub    $0xc,%esp
f0101b3d:	6a 00                	push   $0x0
f0101b3f:	e8 27 f5 ff ff       	call   f010106b <page_alloc>
f0101b44:	83 c4 10             	add    $0x10,%esp
f0101b47:	85 c0                	test   %eax,%eax
f0101b49:	0f 85 ae 08 00 00    	jne    f01023fd <mem_init+0xf9d>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b4f:	83 ec 04             	sub    $0x4,%esp
f0101b52:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b55:	50                   	push   %eax
f0101b56:	6a 00                	push   $0x0
f0101b58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b5b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b61:	ff 30                	pushl  (%eax)
f0101b63:	e8 85 f7 ff ff       	call   f01012ed <page_lookup>
f0101b68:	83 c4 10             	add    $0x10,%esp
f0101b6b:	85 c0                	test   %eax,%eax
f0101b6d:	0f 85 ac 08 00 00    	jne    f010241f <mem_init+0xfbf>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b73:	6a 02                	push   $0x2
f0101b75:	6a 00                	push   $0x0
f0101b77:	57                   	push   %edi
f0101b78:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b7b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101b81:	ff 30                	pushl  (%eax)
f0101b83:	e8 41 f8 ff ff       	call   f01013c9 <page_insert>
f0101b88:	83 c4 10             	add    $0x10,%esp
f0101b8b:	85 c0                	test   %eax,%eax
f0101b8d:	0f 89 ae 08 00 00    	jns    f0102441 <mem_init+0xfe1>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b93:	83 ec 0c             	sub    $0xc,%esp
f0101b96:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b99:	e8 55 f5 ff ff       	call   f01010f3 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b9e:	6a 02                	push   $0x2
f0101ba0:	6a 00                	push   $0x0
f0101ba2:	57                   	push   %edi
f0101ba3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ba6:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bac:	ff 30                	pushl  (%eax)
f0101bae:	e8 16 f8 ff ff       	call   f01013c9 <page_insert>
f0101bb3:	83 c4 20             	add    $0x20,%esp
f0101bb6:	85 c0                	test   %eax,%eax
f0101bb8:	0f 85 a5 08 00 00    	jne    f0102463 <mem_init+0x1003>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101bbe:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bc1:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101bc7:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101bc9:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101bcf:	8b 08                	mov    (%eax),%ecx
f0101bd1:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101bd4:	8b 13                	mov    (%ebx),%edx
f0101bd6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101bdc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bdf:	29 c8                	sub    %ecx,%eax
f0101be1:	c1 f8 03             	sar    $0x3,%eax
f0101be4:	c1 e0 0c             	shl    $0xc,%eax
f0101be7:	39 c2                	cmp    %eax,%edx
f0101be9:	0f 85 96 08 00 00    	jne    f0102485 <mem_init+0x1025>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101bef:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bf4:	89 d8                	mov    %ebx,%eax
f0101bf6:	e8 69 ee ff ff       	call   f0100a64 <check_va2pa>
f0101bfb:	89 fa                	mov    %edi,%edx
f0101bfd:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101c00:	c1 fa 03             	sar    $0x3,%edx
f0101c03:	c1 e2 0c             	shl    $0xc,%edx
f0101c06:	39 d0                	cmp    %edx,%eax
f0101c08:	0f 85 99 08 00 00    	jne    f01024a7 <mem_init+0x1047>
	assert(pp1->pp_ref == 1);
f0101c0e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101c13:	0f 85 b0 08 00 00    	jne    f01024c9 <mem_init+0x1069>
	assert(pp0->pp_ref == 1);
f0101c19:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c1c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c21:	0f 85 c4 08 00 00    	jne    f01024eb <mem_init+0x108b>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c27:	6a 02                	push   $0x2
f0101c29:	68 00 10 00 00       	push   $0x1000
f0101c2e:	56                   	push   %esi
f0101c2f:	53                   	push   %ebx
f0101c30:	e8 94 f7 ff ff       	call   f01013c9 <page_insert>
f0101c35:	83 c4 10             	add    $0x10,%esp
f0101c38:	85 c0                	test   %eax,%eax
f0101c3a:	0f 85 cd 08 00 00    	jne    f010250d <mem_init+0x10ad>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c40:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c45:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101c48:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101c4e:	8b 00                	mov    (%eax),%eax
f0101c50:	e8 0f ee ff ff       	call   f0100a64 <check_va2pa>
f0101c55:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101c5b:	89 f1                	mov    %esi,%ecx
f0101c5d:	2b 0a                	sub    (%edx),%ecx
f0101c5f:	89 ca                	mov    %ecx,%edx
f0101c61:	c1 fa 03             	sar    $0x3,%edx
f0101c64:	c1 e2 0c             	shl    $0xc,%edx
f0101c67:	39 d0                	cmp    %edx,%eax
f0101c69:	0f 85 c0 08 00 00    	jne    f010252f <mem_init+0x10cf>
	assert(pp2->pp_ref == 1);
f0101c6f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c74:	0f 85 d7 08 00 00    	jne    f0102551 <mem_init+0x10f1>

	// should be no free memory
	assert(!page_alloc(0));
f0101c7a:	83 ec 0c             	sub    $0xc,%esp
f0101c7d:	6a 00                	push   $0x0
f0101c7f:	e8 e7 f3 ff ff       	call   f010106b <page_alloc>
f0101c84:	83 c4 10             	add    $0x10,%esp
f0101c87:	85 c0                	test   %eax,%eax
f0101c89:	0f 85 e4 08 00 00    	jne    f0102573 <mem_init+0x1113>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c8f:	6a 02                	push   $0x2
f0101c91:	68 00 10 00 00       	push   $0x1000
f0101c96:	56                   	push   %esi
f0101c97:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c9a:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ca0:	ff 30                	pushl  (%eax)
f0101ca2:	e8 22 f7 ff ff       	call   f01013c9 <page_insert>
f0101ca7:	83 c4 10             	add    $0x10,%esp
f0101caa:	85 c0                	test   %eax,%eax
f0101cac:	0f 85 e3 08 00 00    	jne    f0102595 <mem_init+0x1135>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cb2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cb7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101cba:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101cc0:	8b 00                	mov    (%eax),%eax
f0101cc2:	e8 9d ed ff ff       	call   f0100a64 <check_va2pa>
f0101cc7:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101ccd:	89 f1                	mov    %esi,%ecx
f0101ccf:	2b 0a                	sub    (%edx),%ecx
f0101cd1:	89 ca                	mov    %ecx,%edx
f0101cd3:	c1 fa 03             	sar    $0x3,%edx
f0101cd6:	c1 e2 0c             	shl    $0xc,%edx
f0101cd9:	39 d0                	cmp    %edx,%eax
f0101cdb:	0f 85 d6 08 00 00    	jne    f01025b7 <mem_init+0x1157>
	assert(pp2->pp_ref == 1);
f0101ce1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ce6:	0f 85 ed 08 00 00    	jne    f01025d9 <mem_init+0x1179>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cec:	83 ec 0c             	sub    $0xc,%esp
f0101cef:	6a 00                	push   $0x0
f0101cf1:	e8 75 f3 ff ff       	call   f010106b <page_alloc>
f0101cf6:	83 c4 10             	add    $0x10,%esp
f0101cf9:	85 c0                	test   %eax,%eax
f0101cfb:	0f 85 fa 08 00 00    	jne    f01025fb <mem_init+0x119b>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d01:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101d04:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d0a:	8b 10                	mov    (%eax),%edx
f0101d0c:	8b 02                	mov    (%edx),%eax
f0101d0e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101d13:	89 c3                	mov    %eax,%ebx
f0101d15:	c1 eb 0c             	shr    $0xc,%ebx
f0101d18:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f0101d1e:	3b 19                	cmp    (%ecx),%ebx
f0101d20:	0f 83 f7 08 00 00    	jae    f010261d <mem_init+0x11bd>
	return (void *)(pa + KERNBASE);
f0101d26:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d2b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d2e:	83 ec 04             	sub    $0x4,%esp
f0101d31:	6a 00                	push   $0x0
f0101d33:	68 00 10 00 00       	push   $0x1000
f0101d38:	52                   	push   %edx
f0101d39:	e8 2d f4 ff ff       	call   f010116b <pgdir_walk>
f0101d3e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d41:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d44:	83 c4 10             	add    $0x10,%esp
f0101d47:	39 d0                	cmp    %edx,%eax
f0101d49:	0f 85 ea 08 00 00    	jne    f0102639 <mem_init+0x11d9>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d4f:	6a 06                	push   $0x6
f0101d51:	68 00 10 00 00       	push   $0x1000
f0101d56:	56                   	push   %esi
f0101d57:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d5a:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d60:	ff 30                	pushl  (%eax)
f0101d62:	e8 62 f6 ff ff       	call   f01013c9 <page_insert>
f0101d67:	83 c4 10             	add    $0x10,%esp
f0101d6a:	85 c0                	test   %eax,%eax
f0101d6c:	0f 85 e9 08 00 00    	jne    f010265b <mem_init+0x11fb>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d72:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d75:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101d7b:	8b 18                	mov    (%eax),%ebx
f0101d7d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d82:	89 d8                	mov    %ebx,%eax
f0101d84:	e8 db ec ff ff       	call   f0100a64 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101d89:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101d8c:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101d92:	89 f1                	mov    %esi,%ecx
f0101d94:	2b 0a                	sub    (%edx),%ecx
f0101d96:	89 ca                	mov    %ecx,%edx
f0101d98:	c1 fa 03             	sar    $0x3,%edx
f0101d9b:	c1 e2 0c             	shl    $0xc,%edx
f0101d9e:	39 d0                	cmp    %edx,%eax
f0101da0:	0f 85 d7 08 00 00    	jne    f010267d <mem_init+0x121d>
	assert(pp2->pp_ref == 1);
f0101da6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dab:	0f 85 ee 08 00 00    	jne    f010269f <mem_init+0x123f>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101db1:	83 ec 04             	sub    $0x4,%esp
f0101db4:	6a 00                	push   $0x0
f0101db6:	68 00 10 00 00       	push   $0x1000
f0101dbb:	53                   	push   %ebx
f0101dbc:	e8 aa f3 ff ff       	call   f010116b <pgdir_walk>
f0101dc1:	83 c4 10             	add    $0x10,%esp
f0101dc4:	f6 00 04             	testb  $0x4,(%eax)
f0101dc7:	0f 84 f4 08 00 00    	je     f01026c1 <mem_init+0x1261>
	assert(kern_pgdir[0] & PTE_U);
f0101dcd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dd0:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101dd6:	8b 00                	mov    (%eax),%eax
f0101dd8:	f6 00 04             	testb  $0x4,(%eax)
f0101ddb:	0f 84 02 09 00 00    	je     f01026e3 <mem_init+0x1283>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101de1:	6a 02                	push   $0x2
f0101de3:	68 00 10 00 00       	push   $0x1000
f0101de8:	56                   	push   %esi
f0101de9:	50                   	push   %eax
f0101dea:	e8 da f5 ff ff       	call   f01013c9 <page_insert>
f0101def:	83 c4 10             	add    $0x10,%esp
f0101df2:	85 c0                	test   %eax,%eax
f0101df4:	0f 85 0b 09 00 00    	jne    f0102705 <mem_init+0x12a5>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101dfa:	83 ec 04             	sub    $0x4,%esp
f0101dfd:	6a 00                	push   $0x0
f0101dff:	68 00 10 00 00       	push   $0x1000
f0101e04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e07:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e0d:	ff 30                	pushl  (%eax)
f0101e0f:	e8 57 f3 ff ff       	call   f010116b <pgdir_walk>
f0101e14:	83 c4 10             	add    $0x10,%esp
f0101e17:	f6 00 02             	testb  $0x2,(%eax)
f0101e1a:	0f 84 07 09 00 00    	je     f0102727 <mem_init+0x12c7>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e20:	83 ec 04             	sub    $0x4,%esp
f0101e23:	6a 00                	push   $0x0
f0101e25:	68 00 10 00 00       	push   $0x1000
f0101e2a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e2d:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e33:	ff 30                	pushl  (%eax)
f0101e35:	e8 31 f3 ff ff       	call   f010116b <pgdir_walk>
f0101e3a:	83 c4 10             	add    $0x10,%esp
f0101e3d:	f6 00 04             	testb  $0x4,(%eax)
f0101e40:	0f 85 03 09 00 00    	jne    f0102749 <mem_init+0x12e9>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e46:	6a 02                	push   $0x2
f0101e48:	68 00 00 40 00       	push   $0x400000
f0101e4d:	ff 75 d0             	pushl  -0x30(%ebp)
f0101e50:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e53:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e59:	ff 30                	pushl  (%eax)
f0101e5b:	e8 69 f5 ff ff       	call   f01013c9 <page_insert>
f0101e60:	83 c4 10             	add    $0x10,%esp
f0101e63:	85 c0                	test   %eax,%eax
f0101e65:	0f 89 00 09 00 00    	jns    f010276b <mem_init+0x130b>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e6b:	6a 02                	push   $0x2
f0101e6d:	68 00 10 00 00       	push   $0x1000
f0101e72:	57                   	push   %edi
f0101e73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e76:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101e7c:	ff 30                	pushl  (%eax)
f0101e7e:	e8 46 f5 ff ff       	call   f01013c9 <page_insert>
f0101e83:	83 c4 10             	add    $0x10,%esp
f0101e86:	85 c0                	test   %eax,%eax
f0101e88:	0f 85 ff 08 00 00    	jne    f010278d <mem_init+0x132d>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e8e:	83 ec 04             	sub    $0x4,%esp
f0101e91:	6a 00                	push   $0x0
f0101e93:	68 00 10 00 00       	push   $0x1000
f0101e98:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e9b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ea1:	ff 30                	pushl  (%eax)
f0101ea3:	e8 c3 f2 ff ff       	call   f010116b <pgdir_walk>
f0101ea8:	83 c4 10             	add    $0x10,%esp
f0101eab:	f6 00 04             	testb  $0x4,(%eax)
f0101eae:	0f 85 fb 08 00 00    	jne    f01027af <mem_init+0x134f>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101eb4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eb7:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0101ebd:	8b 18                	mov    (%eax),%ebx
f0101ebf:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ec4:	89 d8                	mov    %ebx,%eax
f0101ec6:	e8 99 eb ff ff       	call   f0100a64 <check_va2pa>
f0101ecb:	89 c2                	mov    %eax,%edx
f0101ecd:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ed0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ed3:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0101ed9:	89 f9                	mov    %edi,%ecx
f0101edb:	2b 08                	sub    (%eax),%ecx
f0101edd:	89 c8                	mov    %ecx,%eax
f0101edf:	c1 f8 03             	sar    $0x3,%eax
f0101ee2:	c1 e0 0c             	shl    $0xc,%eax
f0101ee5:	39 c2                	cmp    %eax,%edx
f0101ee7:	0f 85 e4 08 00 00    	jne    f01027d1 <mem_init+0x1371>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101eed:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ef2:	89 d8                	mov    %ebx,%eax
f0101ef4:	e8 6b eb ff ff       	call   f0100a64 <check_va2pa>
f0101ef9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101efc:	0f 85 f1 08 00 00    	jne    f01027f3 <mem_init+0x1393>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f02:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101f07:	0f 85 08 09 00 00    	jne    f0102815 <mem_init+0x13b5>
	assert(pp2->pp_ref == 0);
f0101f0d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f12:	0f 85 1f 09 00 00    	jne    f0102837 <mem_init+0x13d7>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f18:	83 ec 0c             	sub    $0xc,%esp
f0101f1b:	6a 00                	push   $0x0
f0101f1d:	e8 49 f1 ff ff       	call   f010106b <page_alloc>
f0101f22:	83 c4 10             	add    $0x10,%esp
f0101f25:	39 c6                	cmp    %eax,%esi
f0101f27:	0f 85 2c 09 00 00    	jne    f0102859 <mem_init+0x13f9>
f0101f2d:	85 c0                	test   %eax,%eax
f0101f2f:	0f 84 24 09 00 00    	je     f0102859 <mem_init+0x13f9>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f35:	83 ec 08             	sub    $0x8,%esp
f0101f38:	6a 00                	push   $0x0
f0101f3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f3d:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101f43:	ff 33                	pushl  (%ebx)
f0101f45:	e8 07 f4 ff ff       	call   f0101351 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f4a:	8b 1b                	mov    (%ebx),%ebx
f0101f4c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f51:	89 d8                	mov    %ebx,%eax
f0101f53:	e8 0c eb ff ff       	call   f0100a64 <check_va2pa>
f0101f58:	83 c4 10             	add    $0x10,%esp
f0101f5b:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f5e:	0f 85 17 09 00 00    	jne    f010287b <mem_init+0x141b>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f64:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f69:	89 d8                	mov    %ebx,%eax
f0101f6b:	e8 f4 ea ff ff       	call   f0100a64 <check_va2pa>
f0101f70:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101f73:	c7 c2 d0 96 11 f0    	mov    $0xf01196d0,%edx
f0101f79:	89 f9                	mov    %edi,%ecx
f0101f7b:	2b 0a                	sub    (%edx),%ecx
f0101f7d:	89 ca                	mov    %ecx,%edx
f0101f7f:	c1 fa 03             	sar    $0x3,%edx
f0101f82:	c1 e2 0c             	shl    $0xc,%edx
f0101f85:	39 d0                	cmp    %edx,%eax
f0101f87:	0f 85 10 09 00 00    	jne    f010289d <mem_init+0x143d>
	assert(pp1->pp_ref == 1);
f0101f8d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101f92:	0f 85 27 09 00 00    	jne    f01028bf <mem_init+0x145f>
	assert(pp2->pp_ref == 0);
f0101f98:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f9d:	0f 85 3e 09 00 00    	jne    f01028e1 <mem_init+0x1481>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101fa3:	6a 00                	push   $0x0
f0101fa5:	68 00 10 00 00       	push   $0x1000
f0101faa:	57                   	push   %edi
f0101fab:	53                   	push   %ebx
f0101fac:	e8 18 f4 ff ff       	call   f01013c9 <page_insert>
f0101fb1:	83 c4 10             	add    $0x10,%esp
f0101fb4:	85 c0                	test   %eax,%eax
f0101fb6:	0f 85 47 09 00 00    	jne    f0102903 <mem_init+0x14a3>
	assert(pp1->pp_ref);
f0101fbc:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101fc1:	0f 84 5e 09 00 00    	je     f0102925 <mem_init+0x14c5>
	assert(pp1->pp_link == NULL);
f0101fc7:	83 3f 00             	cmpl   $0x0,(%edi)
f0101fca:	0f 85 77 09 00 00    	jne    f0102947 <mem_init+0x14e7>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101fd0:	83 ec 08             	sub    $0x8,%esp
f0101fd3:	68 00 10 00 00       	push   $0x1000
f0101fd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fdb:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f0101fe1:	ff 33                	pushl  (%ebx)
f0101fe3:	e8 69 f3 ff ff       	call   f0101351 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101fe8:	8b 1b                	mov    (%ebx),%ebx
f0101fea:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fef:	89 d8                	mov    %ebx,%eax
f0101ff1:	e8 6e ea ff ff       	call   f0100a64 <check_va2pa>
f0101ff6:	83 c4 10             	add    $0x10,%esp
f0101ff9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ffc:	0f 85 67 09 00 00    	jne    f0102969 <mem_init+0x1509>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102002:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102007:	89 d8                	mov    %ebx,%eax
f0102009:	e8 56 ea ff ff       	call   f0100a64 <check_va2pa>
f010200e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102011:	0f 85 74 09 00 00    	jne    f010298b <mem_init+0x152b>
	assert(pp1->pp_ref == 0);
f0102017:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010201c:	0f 85 8b 09 00 00    	jne    f01029ad <mem_init+0x154d>
	assert(pp2->pp_ref == 0);
f0102022:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102027:	0f 85 a2 09 00 00    	jne    f01029cf <mem_init+0x156f>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010202d:	83 ec 0c             	sub    $0xc,%esp
f0102030:	6a 00                	push   $0x0
f0102032:	e8 34 f0 ff ff       	call   f010106b <page_alloc>
f0102037:	83 c4 10             	add    $0x10,%esp
f010203a:	85 c0                	test   %eax,%eax
f010203c:	0f 84 af 09 00 00    	je     f01029f1 <mem_init+0x1591>
f0102042:	39 c7                	cmp    %eax,%edi
f0102044:	0f 85 a7 09 00 00    	jne    f01029f1 <mem_init+0x1591>

	// should be no free memory
	assert(!page_alloc(0));
f010204a:	83 ec 0c             	sub    $0xc,%esp
f010204d:	6a 00                	push   $0x0
f010204f:	e8 17 f0 ff ff       	call   f010106b <page_alloc>
f0102054:	83 c4 10             	add    $0x10,%esp
f0102057:	85 c0                	test   %eax,%eax
f0102059:	0f 85 b4 09 00 00    	jne    f0102a13 <mem_init+0x15b3>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010205f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102062:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102068:	8b 08                	mov    (%eax),%ecx
f010206a:	8b 11                	mov    (%ecx),%edx
f010206c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102072:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102078:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010207b:	2b 18                	sub    (%eax),%ebx
f010207d:	89 d8                	mov    %ebx,%eax
f010207f:	c1 f8 03             	sar    $0x3,%eax
f0102082:	c1 e0 0c             	shl    $0xc,%eax
f0102085:	39 c2                	cmp    %eax,%edx
f0102087:	0f 85 a8 09 00 00    	jne    f0102a35 <mem_init+0x15d5>
	kern_pgdir[0] = 0;
f010208d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102093:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102096:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010209b:	0f 85 b6 09 00 00    	jne    f0102a57 <mem_init+0x15f7>
	pp0->pp_ref = 0;
f01020a1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020a4:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020aa:	83 ec 0c             	sub    $0xc,%esp
f01020ad:	50                   	push   %eax
f01020ae:	e8 40 f0 ff ff       	call   f01010f3 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020b3:	83 c4 0c             	add    $0xc,%esp
f01020b6:	6a 01                	push   $0x1
f01020b8:	68 00 10 40 00       	push   $0x401000
f01020bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020c0:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f01020c6:	ff 33                	pushl  (%ebx)
f01020c8:	e8 9e f0 ff ff       	call   f010116b <pgdir_walk>
f01020cd:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020d0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020d3:	8b 1b                	mov    (%ebx),%ebx
f01020d5:	8b 53 04             	mov    0x4(%ebx),%edx
f01020d8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01020de:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01020e1:	c7 c1 c8 96 11 f0    	mov    $0xf01196c8,%ecx
f01020e7:	8b 09                	mov    (%ecx),%ecx
f01020e9:	89 d0                	mov    %edx,%eax
f01020eb:	c1 e8 0c             	shr    $0xc,%eax
f01020ee:	83 c4 10             	add    $0x10,%esp
f01020f1:	39 c8                	cmp    %ecx,%eax
f01020f3:	0f 83 80 09 00 00    	jae    f0102a79 <mem_init+0x1619>
	assert(ptep == ptep1 + PTX(va));
f01020f9:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01020ff:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0102102:	0f 85 8d 09 00 00    	jne    f0102a95 <mem_init+0x1635>
	kern_pgdir[PDX(va)] = 0;
f0102108:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f010210f:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102112:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102118:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010211b:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102121:	2b 18                	sub    (%eax),%ebx
f0102123:	89 d8                	mov    %ebx,%eax
f0102125:	c1 f8 03             	sar    $0x3,%eax
f0102128:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010212b:	89 c2                	mov    %eax,%edx
f010212d:	c1 ea 0c             	shr    $0xc,%edx
f0102130:	39 d1                	cmp    %edx,%ecx
f0102132:	0f 86 7f 09 00 00    	jbe    f0102ab7 <mem_init+0x1657>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102138:	83 ec 04             	sub    $0x4,%esp
f010213b:	68 00 10 00 00       	push   $0x1000
f0102140:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102145:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010214a:	50                   	push   %eax
f010214b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010214e:	e8 64 1d 00 00       	call   f0103eb7 <memset>
	page_free(pp0);
f0102153:	83 c4 04             	add    $0x4,%esp
f0102156:	ff 75 d0             	pushl  -0x30(%ebp)
f0102159:	e8 95 ef ff ff       	call   f01010f3 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010215e:	83 c4 0c             	add    $0xc,%esp
f0102161:	6a 01                	push   $0x1
f0102163:	6a 00                	push   $0x0
f0102165:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102168:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f010216e:	ff 30                	pushl  (%eax)
f0102170:	e8 f6 ef ff ff       	call   f010116b <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102175:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010217b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010217e:	2b 10                	sub    (%eax),%edx
f0102180:	c1 fa 03             	sar    $0x3,%edx
f0102183:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102186:	89 d1                	mov    %edx,%ecx
f0102188:	c1 e9 0c             	shr    $0xc,%ecx
f010218b:	83 c4 10             	add    $0x10,%esp
f010218e:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0102194:	3b 08                	cmp    (%eax),%ecx
f0102196:	0f 83 34 09 00 00    	jae    f0102ad0 <mem_init+0x1670>
	return (void *)(pa + KERNBASE);
f010219c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01021a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01021a5:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021ab:	f6 00 01             	testb  $0x1,(%eax)
f01021ae:	0f 85 35 09 00 00    	jne    f0102ae9 <mem_init+0x1689>
f01021b4:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01021b7:	39 d0                	cmp    %edx,%eax
f01021b9:	75 f0                	jne    f01021ab <mem_init+0xd4b>
	kern_pgdir[0] = 0;
f01021bb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021be:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f01021c4:	8b 00                	mov    (%eax),%eax
f01021c6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021cc:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021cf:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021d5:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01021d8:	89 93 90 1f 00 00    	mov    %edx,0x1f90(%ebx)

	// free the pages we took
	page_free(pp0);
f01021de:	83 ec 0c             	sub    $0xc,%esp
f01021e1:	50                   	push   %eax
f01021e2:	e8 0c ef ff ff       	call   f01010f3 <page_free>
	page_free(pp1);
f01021e7:	89 3c 24             	mov    %edi,(%esp)
f01021ea:	e8 04 ef ff ff       	call   f01010f3 <page_free>
	page_free(pp2);
f01021ef:	89 34 24             	mov    %esi,(%esp)
f01021f2:	e8 fc ee ff ff       	call   f01010f3 <page_free>

	cprintf("check_page() succeeded!\n");
f01021f7:	8d 83 7b df fe ff    	lea    -0x12085(%ebx),%eax
f01021fd:	89 04 24             	mov    %eax,(%esp)
f0102200:	e8 69 10 00 00       	call   f010326e <cprintf>
	boot_map_region(kern_pgdir,UPAGES,ROUNDUP((npages*sizeof(struct PageInfo)),PGSIZE),PADDR((void*)pages),PTE_U|PTE_P);
f0102205:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f010220b:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010220d:	83 c4 10             	add    $0x10,%esp
f0102210:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102215:	0f 86 f0 08 00 00    	jbe    f0102b0b <mem_init+0x16ab>
f010221b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010221e:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102224:	8b 12                	mov    (%edx),%edx
f0102226:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f010222d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102233:	83 ec 08             	sub    $0x8,%esp
f0102236:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102238:	05 00 00 00 10       	add    $0x10000000,%eax
f010223d:	50                   	push   %eax
f010223e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102243:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102249:	8b 00                	mov    (%eax),%eax
f010224b:	e8 05 f0 ff ff       	call   f0101255 <boot_map_region>
	boot_map_region(kern_pgdir,(uintptr_t)pages,ROUNDUP((npages*sizeof(struct PageInfo)),PGSIZE),PADDR((void*)pages),PTE_W|PTE_P);
f0102250:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102256:	8b 10                	mov    (%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f0102258:	83 c4 10             	add    $0x10,%esp
f010225b:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102261:	0f 86 c0 08 00 00    	jbe    f0102b27 <mem_init+0x16c7>
f0102267:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010226a:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f0102270:	8b 00                	mov    (%eax),%eax
f0102272:	8d 0c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ecx
f0102279:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010227f:	83 ec 08             	sub    $0x8,%esp
f0102282:	6a 03                	push   $0x3
	return (physaddr_t)kva - KERNBASE;
f0102284:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f010228a:	50                   	push   %eax
f010228b:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102291:	8b 00                	mov    (%eax),%eax
f0102293:	e8 bd ef ff ff       	call   f0101255 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102298:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f010229e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01022a1:	83 c4 10             	add    $0x10,%esp
f01022a4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01022a9:	0f 86 94 08 00 00    	jbe    f0102b43 <mem_init+0x16e3>
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,(physaddr_t)(PTE_ADDR(PADDR(bootstack))),PTE_W|PTE_P);
f01022af:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01022b2:	c7 c3 cc 96 11 f0    	mov    $0xf01196cc,%ebx
f01022b8:	83 ec 08             	sub    $0x8,%esp
f01022bb:	6a 03                	push   $0x3
	return (physaddr_t)kva - KERNBASE;
f01022bd:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01022c0:	05 00 00 00 10       	add    $0x10000000,%eax
f01022c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01022ca:	50                   	push   %eax
f01022cb:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01022d0:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01022d5:	8b 03                	mov    (%ebx),%eax
f01022d7:	e8 79 ef ff ff       	call   f0101255 <boot_map_region>
	boot_map_region(kern_pgdir,KERNBASE,ROUNDUP(((long long)1<<32)-KERNBASE,PGSIZE),0,PTE_W|PTE_P);
f01022dc:	83 c4 08             	add    $0x8,%esp
f01022df:	6a 03                	push   $0x3
f01022e1:	6a 00                	push   $0x0
f01022e3:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01022e8:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01022ed:	8b 03                	mov    (%ebx),%eax
f01022ef:	e8 61 ef ff ff       	call   f0101255 <boot_map_region>
	pgdir = kern_pgdir;
f01022f4:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01022f6:	c7 c0 c8 96 11 f0    	mov    $0xf01196c8,%eax
f01022fc:	8b 00                	mov    (%eax),%eax
f01022fe:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102301:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102308:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010230d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102310:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102316:	8b 00                	mov    (%eax),%eax
f0102318:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f010231b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f010231e:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0102324:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0102327:	bf 00 00 00 00       	mov    $0x0,%edi
f010232c:	e9 57 08 00 00       	jmp    f0102b88 <mem_init+0x1728>
	assert(nfree == 0);
f0102331:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102334:	8d 83 a4 de fe ff    	lea    -0x1215c(%ebx),%eax
f010233a:	50                   	push   %eax
f010233b:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102341:	50                   	push   %eax
f0102342:	68 e8 02 00 00       	push   $0x2e8
f0102347:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010234d:	50                   	push   %eax
f010234e:	e8 46 dd ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102353:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102356:	8d 83 b2 dd fe ff    	lea    -0x1224e(%ebx),%eax
f010235c:	50                   	push   %eax
f010235d:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102363:	50                   	push   %eax
f0102364:	68 41 03 00 00       	push   $0x341
f0102369:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010236f:	50                   	push   %eax
f0102370:	e8 24 dd ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102375:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102378:	8d 83 c8 dd fe ff    	lea    -0x12238(%ebx),%eax
f010237e:	50                   	push   %eax
f010237f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102385:	50                   	push   %eax
f0102386:	68 42 03 00 00       	push   $0x342
f010238b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102391:	50                   	push   %eax
f0102392:	e8 02 dd ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102397:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010239a:	8d 83 de dd fe ff    	lea    -0x12222(%ebx),%eax
f01023a0:	50                   	push   %eax
f01023a1:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01023a7:	50                   	push   %eax
f01023a8:	68 43 03 00 00       	push   $0x343
f01023ad:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01023b3:	50                   	push   %eax
f01023b4:	e8 e0 dc ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01023b9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023bc:	8d 83 f4 dd fe ff    	lea    -0x1220c(%ebx),%eax
f01023c2:	50                   	push   %eax
f01023c3:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01023c9:	50                   	push   %eax
f01023ca:	68 46 03 00 00       	push   $0x346
f01023cf:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01023d5:	50                   	push   %eax
f01023d6:	e8 be dc ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01023db:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023de:	8d 83 e8 d6 fe ff    	lea    -0x12918(%ebx),%eax
f01023e4:	50                   	push   %eax
f01023e5:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01023eb:	50                   	push   %eax
f01023ec:	68 47 03 00 00       	push   $0x347
f01023f1:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01023f7:	50                   	push   %eax
f01023f8:	e8 9c dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01023fd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102400:	8d 83 5d de fe ff    	lea    -0x121a3(%ebx),%eax
f0102406:	50                   	push   %eax
f0102407:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010240d:	50                   	push   %eax
f010240e:	68 4e 03 00 00       	push   $0x34e
f0102413:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102419:	50                   	push   %eax
f010241a:	e8 7a dc ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010241f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102422:	8d 83 28 d7 fe ff    	lea    -0x128d8(%ebx),%eax
f0102428:	50                   	push   %eax
f0102429:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010242f:	50                   	push   %eax
f0102430:	68 51 03 00 00       	push   $0x351
f0102435:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010243b:	50                   	push   %eax
f010243c:	e8 58 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102441:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102444:	8d 83 60 d7 fe ff    	lea    -0x128a0(%ebx),%eax
f010244a:	50                   	push   %eax
f010244b:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102451:	50                   	push   %eax
f0102452:	68 54 03 00 00       	push   $0x354
f0102457:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010245d:	50                   	push   %eax
f010245e:	e8 36 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102463:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102466:	8d 83 90 d7 fe ff    	lea    -0x12870(%ebx),%eax
f010246c:	50                   	push   %eax
f010246d:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102473:	50                   	push   %eax
f0102474:	68 58 03 00 00       	push   $0x358
f0102479:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010247f:	50                   	push   %eax
f0102480:	e8 14 dc ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102485:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102488:	8d 83 c0 d7 fe ff    	lea    -0x12840(%ebx),%eax
f010248e:	50                   	push   %eax
f010248f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102495:	50                   	push   %eax
f0102496:	68 59 03 00 00       	push   $0x359
f010249b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01024a1:	50                   	push   %eax
f01024a2:	e8 f2 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01024a7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024aa:	8d 83 e8 d7 fe ff    	lea    -0x12818(%ebx),%eax
f01024b0:	50                   	push   %eax
f01024b1:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01024b7:	50                   	push   %eax
f01024b8:	68 5a 03 00 00       	push   $0x35a
f01024bd:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01024c3:	50                   	push   %eax
f01024c4:	e8 d0 db ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01024c9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024cc:	8d 83 af de fe ff    	lea    -0x12151(%ebx),%eax
f01024d2:	50                   	push   %eax
f01024d3:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01024d9:	50                   	push   %eax
f01024da:	68 5b 03 00 00       	push   $0x35b
f01024df:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01024e5:	50                   	push   %eax
f01024e6:	e8 ae db ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01024eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024ee:	8d 83 c0 de fe ff    	lea    -0x12140(%ebx),%eax
f01024f4:	50                   	push   %eax
f01024f5:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01024fb:	50                   	push   %eax
f01024fc:	68 5c 03 00 00       	push   $0x35c
f0102501:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102507:	50                   	push   %eax
f0102508:	e8 8c db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010250d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102510:	8d 83 18 d8 fe ff    	lea    -0x127e8(%ebx),%eax
f0102516:	50                   	push   %eax
f0102517:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010251d:	50                   	push   %eax
f010251e:	68 5f 03 00 00       	push   $0x35f
f0102523:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102529:	50                   	push   %eax
f010252a:	e8 6a db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010252f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102532:	8d 83 54 d8 fe ff    	lea    -0x127ac(%ebx),%eax
f0102538:	50                   	push   %eax
f0102539:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010253f:	50                   	push   %eax
f0102540:	68 60 03 00 00       	push   $0x360
f0102545:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010254b:	50                   	push   %eax
f010254c:	e8 48 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102551:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102554:	8d 83 d1 de fe ff    	lea    -0x1212f(%ebx),%eax
f010255a:	50                   	push   %eax
f010255b:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102561:	50                   	push   %eax
f0102562:	68 61 03 00 00       	push   $0x361
f0102567:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010256d:	50                   	push   %eax
f010256e:	e8 26 db ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102573:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102576:	8d 83 5d de fe ff    	lea    -0x121a3(%ebx),%eax
f010257c:	50                   	push   %eax
f010257d:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102583:	50                   	push   %eax
f0102584:	68 64 03 00 00       	push   $0x364
f0102589:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010258f:	50                   	push   %eax
f0102590:	e8 04 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102595:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102598:	8d 83 18 d8 fe ff    	lea    -0x127e8(%ebx),%eax
f010259e:	50                   	push   %eax
f010259f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01025a5:	50                   	push   %eax
f01025a6:	68 67 03 00 00       	push   $0x367
f01025ab:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01025b1:	50                   	push   %eax
f01025b2:	e8 e2 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01025b7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025ba:	8d 83 54 d8 fe ff    	lea    -0x127ac(%ebx),%eax
f01025c0:	50                   	push   %eax
f01025c1:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01025c7:	50                   	push   %eax
f01025c8:	68 68 03 00 00       	push   $0x368
f01025cd:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01025d3:	50                   	push   %eax
f01025d4:	e8 c0 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01025d9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025dc:	8d 83 d1 de fe ff    	lea    -0x1212f(%ebx),%eax
f01025e2:	50                   	push   %eax
f01025e3:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01025e9:	50                   	push   %eax
f01025ea:	68 69 03 00 00       	push   $0x369
f01025ef:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01025f5:	50                   	push   %eax
f01025f6:	e8 9e da ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01025fb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025fe:	8d 83 5d de fe ff    	lea    -0x121a3(%ebx),%eax
f0102604:	50                   	push   %eax
f0102605:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010260b:	50                   	push   %eax
f010260c:	68 6d 03 00 00       	push   $0x36d
f0102611:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102617:	50                   	push   %eax
f0102618:	e8 7c da ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010261d:	50                   	push   %eax
f010261e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102621:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0102627:	50                   	push   %eax
f0102628:	68 70 03 00 00       	push   $0x370
f010262d:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102633:	50                   	push   %eax
f0102634:	e8 60 da ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102639:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010263c:	8d 83 84 d8 fe ff    	lea    -0x1277c(%ebx),%eax
f0102642:	50                   	push   %eax
f0102643:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102649:	50                   	push   %eax
f010264a:	68 71 03 00 00       	push   $0x371
f010264f:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102655:	50                   	push   %eax
f0102656:	e8 3e da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010265b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010265e:	8d 83 c4 d8 fe ff    	lea    -0x1273c(%ebx),%eax
f0102664:	50                   	push   %eax
f0102665:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010266b:	50                   	push   %eax
f010266c:	68 74 03 00 00       	push   $0x374
f0102671:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102677:	50                   	push   %eax
f0102678:	e8 1c da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010267d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102680:	8d 83 54 d8 fe ff    	lea    -0x127ac(%ebx),%eax
f0102686:	50                   	push   %eax
f0102687:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010268d:	50                   	push   %eax
f010268e:	68 75 03 00 00       	push   $0x375
f0102693:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102699:	50                   	push   %eax
f010269a:	e8 fa d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010269f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026a2:	8d 83 d1 de fe ff    	lea    -0x1212f(%ebx),%eax
f01026a8:	50                   	push   %eax
f01026a9:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01026af:	50                   	push   %eax
f01026b0:	68 76 03 00 00       	push   $0x376
f01026b5:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01026bb:	50                   	push   %eax
f01026bc:	e8 d8 d9 ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01026c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026c4:	8d 83 04 d9 fe ff    	lea    -0x126fc(%ebx),%eax
f01026ca:	50                   	push   %eax
f01026cb:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01026d1:	50                   	push   %eax
f01026d2:	68 77 03 00 00       	push   $0x377
f01026d7:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01026dd:	50                   	push   %eax
f01026de:	e8 b6 d9 ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01026e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026e6:	8d 83 e2 de fe ff    	lea    -0x1211e(%ebx),%eax
f01026ec:	50                   	push   %eax
f01026ed:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01026f3:	50                   	push   %eax
f01026f4:	68 78 03 00 00       	push   $0x378
f01026f9:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01026ff:	50                   	push   %eax
f0102700:	e8 94 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102705:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102708:	8d 83 18 d8 fe ff    	lea    -0x127e8(%ebx),%eax
f010270e:	50                   	push   %eax
f010270f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102715:	50                   	push   %eax
f0102716:	68 7b 03 00 00       	push   $0x37b
f010271b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102721:	50                   	push   %eax
f0102722:	e8 72 d9 ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102727:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010272a:	8d 83 38 d9 fe ff    	lea    -0x126c8(%ebx),%eax
f0102730:	50                   	push   %eax
f0102731:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102737:	50                   	push   %eax
f0102738:	68 7c 03 00 00       	push   $0x37c
f010273d:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102743:	50                   	push   %eax
f0102744:	e8 50 d9 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102749:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010274c:	8d 83 6c d9 fe ff    	lea    -0x12694(%ebx),%eax
f0102752:	50                   	push   %eax
f0102753:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102759:	50                   	push   %eax
f010275a:	68 7d 03 00 00       	push   $0x37d
f010275f:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102765:	50                   	push   %eax
f0102766:	e8 2e d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010276b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010276e:	8d 83 a4 d9 fe ff    	lea    -0x1265c(%ebx),%eax
f0102774:	50                   	push   %eax
f0102775:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010277b:	50                   	push   %eax
f010277c:	68 80 03 00 00       	push   $0x380
f0102781:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102787:	50                   	push   %eax
f0102788:	e8 0c d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010278d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102790:	8d 83 dc d9 fe ff    	lea    -0x12624(%ebx),%eax
f0102796:	50                   	push   %eax
f0102797:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010279d:	50                   	push   %eax
f010279e:	68 83 03 00 00       	push   $0x383
f01027a3:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01027a9:	50                   	push   %eax
f01027aa:	e8 ea d8 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01027af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027b2:	8d 83 6c d9 fe ff    	lea    -0x12694(%ebx),%eax
f01027b8:	50                   	push   %eax
f01027b9:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01027bf:	50                   	push   %eax
f01027c0:	68 84 03 00 00       	push   $0x384
f01027c5:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01027cb:	50                   	push   %eax
f01027cc:	e8 c8 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01027d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027d4:	8d 83 18 da fe ff    	lea    -0x125e8(%ebx),%eax
f01027da:	50                   	push   %eax
f01027db:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01027e1:	50                   	push   %eax
f01027e2:	68 87 03 00 00       	push   $0x387
f01027e7:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01027ed:	50                   	push   %eax
f01027ee:	e8 a6 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027f6:	8d 83 44 da fe ff    	lea    -0x125bc(%ebx),%eax
f01027fc:	50                   	push   %eax
f01027fd:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102803:	50                   	push   %eax
f0102804:	68 88 03 00 00       	push   $0x388
f0102809:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010280f:	50                   	push   %eax
f0102810:	e8 84 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f0102815:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102818:	8d 83 f8 de fe ff    	lea    -0x12108(%ebx),%eax
f010281e:	50                   	push   %eax
f010281f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102825:	50                   	push   %eax
f0102826:	68 8a 03 00 00       	push   $0x38a
f010282b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102831:	50                   	push   %eax
f0102832:	e8 62 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102837:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010283a:	8d 83 09 df fe ff    	lea    -0x120f7(%ebx),%eax
f0102840:	50                   	push   %eax
f0102841:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102847:	50                   	push   %eax
f0102848:	68 8b 03 00 00       	push   $0x38b
f010284d:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102853:	50                   	push   %eax
f0102854:	e8 40 d8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102859:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010285c:	8d 83 74 da fe ff    	lea    -0x1258c(%ebx),%eax
f0102862:	50                   	push   %eax
f0102863:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102869:	50                   	push   %eax
f010286a:	68 8e 03 00 00       	push   $0x38e
f010286f:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102875:	50                   	push   %eax
f0102876:	e8 1e d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010287b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010287e:	8d 83 98 da fe ff    	lea    -0x12568(%ebx),%eax
f0102884:	50                   	push   %eax
f0102885:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010288b:	50                   	push   %eax
f010288c:	68 92 03 00 00       	push   $0x392
f0102891:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102897:	50                   	push   %eax
f0102898:	e8 fc d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010289d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028a0:	8d 83 44 da fe ff    	lea    -0x125bc(%ebx),%eax
f01028a6:	50                   	push   %eax
f01028a7:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01028ad:	50                   	push   %eax
f01028ae:	68 93 03 00 00       	push   $0x393
f01028b3:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01028b9:	50                   	push   %eax
f01028ba:	e8 da d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01028bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028c2:	8d 83 af de fe ff    	lea    -0x12151(%ebx),%eax
f01028c8:	50                   	push   %eax
f01028c9:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01028cf:	50                   	push   %eax
f01028d0:	68 94 03 00 00       	push   $0x394
f01028d5:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01028db:	50                   	push   %eax
f01028dc:	e8 b8 d7 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01028e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028e4:	8d 83 09 df fe ff    	lea    -0x120f7(%ebx),%eax
f01028ea:	50                   	push   %eax
f01028eb:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01028f1:	50                   	push   %eax
f01028f2:	68 95 03 00 00       	push   $0x395
f01028f7:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01028fd:	50                   	push   %eax
f01028fe:	e8 96 d7 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102903:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102906:	8d 83 bc da fe ff    	lea    -0x12544(%ebx),%eax
f010290c:	50                   	push   %eax
f010290d:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102913:	50                   	push   %eax
f0102914:	68 98 03 00 00       	push   $0x398
f0102919:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010291f:	50                   	push   %eax
f0102920:	e8 74 d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f0102925:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102928:	8d 83 1a df fe ff    	lea    -0x120e6(%ebx),%eax
f010292e:	50                   	push   %eax
f010292f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102935:	50                   	push   %eax
f0102936:	68 99 03 00 00       	push   $0x399
f010293b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102941:	50                   	push   %eax
f0102942:	e8 52 d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f0102947:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010294a:	8d 83 26 df fe ff    	lea    -0x120da(%ebx),%eax
f0102950:	50                   	push   %eax
f0102951:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102957:	50                   	push   %eax
f0102958:	68 9a 03 00 00       	push   $0x39a
f010295d:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102963:	50                   	push   %eax
f0102964:	e8 30 d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102969:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010296c:	8d 83 98 da fe ff    	lea    -0x12568(%ebx),%eax
f0102972:	50                   	push   %eax
f0102973:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102979:	50                   	push   %eax
f010297a:	68 9e 03 00 00       	push   $0x39e
f010297f:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102985:	50                   	push   %eax
f0102986:	e8 0e d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010298b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010298e:	8d 83 f4 da fe ff    	lea    -0x1250c(%ebx),%eax
f0102994:	50                   	push   %eax
f0102995:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010299b:	50                   	push   %eax
f010299c:	68 9f 03 00 00       	push   $0x39f
f01029a1:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01029a7:	50                   	push   %eax
f01029a8:	e8 ec d6 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f01029ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029b0:	8d 83 3b df fe ff    	lea    -0x120c5(%ebx),%eax
f01029b6:	50                   	push   %eax
f01029b7:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01029bd:	50                   	push   %eax
f01029be:	68 a0 03 00 00       	push   $0x3a0
f01029c3:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01029c9:	50                   	push   %eax
f01029ca:	e8 ca d6 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01029cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029d2:	8d 83 09 df fe ff    	lea    -0x120f7(%ebx),%eax
f01029d8:	50                   	push   %eax
f01029d9:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01029df:	50                   	push   %eax
f01029e0:	68 a1 03 00 00       	push   $0x3a1
f01029e5:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01029eb:	50                   	push   %eax
f01029ec:	e8 a8 d6 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01029f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029f4:	8d 83 1c db fe ff    	lea    -0x124e4(%ebx),%eax
f01029fa:	50                   	push   %eax
f01029fb:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102a01:	50                   	push   %eax
f0102a02:	68 a4 03 00 00       	push   $0x3a4
f0102a07:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102a0d:	50                   	push   %eax
f0102a0e:	e8 86 d6 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102a13:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a16:	8d 83 5d de fe ff    	lea    -0x121a3(%ebx),%eax
f0102a1c:	50                   	push   %eax
f0102a1d:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102a23:	50                   	push   %eax
f0102a24:	68 a7 03 00 00       	push   $0x3a7
f0102a29:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102a2f:	50                   	push   %eax
f0102a30:	e8 64 d6 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102a35:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a38:	8d 83 c0 d7 fe ff    	lea    -0x12840(%ebx),%eax
f0102a3e:	50                   	push   %eax
f0102a3f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102a45:	50                   	push   %eax
f0102a46:	68 aa 03 00 00       	push   $0x3aa
f0102a4b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102a51:	50                   	push   %eax
f0102a52:	e8 42 d6 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102a57:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a5a:	8d 83 c0 de fe ff    	lea    -0x12140(%ebx),%eax
f0102a60:	50                   	push   %eax
f0102a61:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102a67:	50                   	push   %eax
f0102a68:	68 ac 03 00 00       	push   $0x3ac
f0102a6d:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102a73:	50                   	push   %eax
f0102a74:	e8 20 d6 ff ff       	call   f0100099 <_panic>
f0102a79:	52                   	push   %edx
f0102a7a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a7d:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0102a83:	50                   	push   %eax
f0102a84:	68 b3 03 00 00       	push   $0x3b3
f0102a89:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102a8f:	50                   	push   %eax
f0102a90:	e8 04 d6 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102a95:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a98:	8d 83 4c df fe ff    	lea    -0x120b4(%ebx),%eax
f0102a9e:	50                   	push   %eax
f0102a9f:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102aa5:	50                   	push   %eax
f0102aa6:	68 b4 03 00 00       	push   $0x3b4
f0102aab:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102ab1:	50                   	push   %eax
f0102ab2:	e8 e2 d5 ff ff       	call   f0100099 <_panic>
f0102ab7:	50                   	push   %eax
f0102ab8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102abb:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0102ac1:	50                   	push   %eax
f0102ac2:	6a 52                	push   $0x52
f0102ac4:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0102aca:	50                   	push   %eax
f0102acb:	e8 c9 d5 ff ff       	call   f0100099 <_panic>
f0102ad0:	52                   	push   %edx
f0102ad1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ad4:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0102ada:	50                   	push   %eax
f0102adb:	6a 52                	push   $0x52
f0102add:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0102ae3:	50                   	push   %eax
f0102ae4:	e8 b0 d5 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102ae9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aec:	8d 83 64 df fe ff    	lea    -0x1209c(%ebx),%eax
f0102af2:	50                   	push   %eax
f0102af3:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102af9:	50                   	push   %eax
f0102afa:	68 be 03 00 00       	push   $0x3be
f0102aff:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102b05:	50                   	push   %eax
f0102b06:	e8 8e d5 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b0b:	50                   	push   %eax
f0102b0c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b0f:	8d 83 f0 d4 fe ff    	lea    -0x12b10(%ebx),%eax
f0102b15:	50                   	push   %eax
f0102b16:	68 b9 00 00 00       	push   $0xb9
f0102b1b:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102b21:	50                   	push   %eax
f0102b22:	e8 72 d5 ff ff       	call   f0100099 <_panic>
f0102b27:	52                   	push   %edx
f0102b28:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b2b:	8d 83 f0 d4 fe ff    	lea    -0x12b10(%ebx),%eax
f0102b31:	50                   	push   %eax
f0102b32:	68 bb 00 00 00       	push   $0xbb
f0102b37:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102b3d:	50                   	push   %eax
f0102b3e:	e8 56 d5 ff ff       	call   f0100099 <_panic>
f0102b43:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b46:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102b4c:	8d 83 f0 d4 fe ff    	lea    -0x12b10(%ebx),%eax
f0102b52:	50                   	push   %eax
f0102b53:	68 c9 00 00 00       	push   $0xc9
f0102b58:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102b5e:	50                   	push   %eax
f0102b5f:	e8 35 d5 ff ff       	call   f0100099 <_panic>
f0102b64:	ff 75 c0             	pushl  -0x40(%ebp)
f0102b67:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b6a:	8d 83 f0 d4 fe ff    	lea    -0x12b10(%ebx),%eax
f0102b70:	50                   	push   %eax
f0102b71:	68 00 03 00 00       	push   $0x300
f0102b76:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102b7c:	50                   	push   %eax
f0102b7d:	e8 17 d5 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102b82:	81 c7 00 10 00 00    	add    $0x1000,%edi
f0102b88:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0102b8b:	76 3f                	jbe    f0102bcc <mem_init+0x176c>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102b8d:	8d 97 00 00 00 ef    	lea    -0x11000000(%edi),%edx
f0102b93:	89 f0                	mov    %esi,%eax
f0102b95:	e8 ca de ff ff       	call   f0100a64 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102b9a:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102ba1:	76 c1                	jbe    f0102b64 <mem_init+0x1704>
f0102ba3:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102ba6:	39 c2                	cmp    %eax,%edx
f0102ba8:	74 d8                	je     f0102b82 <mem_init+0x1722>
f0102baa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bad:	8d 83 40 db fe ff    	lea    -0x124c0(%ebx),%eax
f0102bb3:	50                   	push   %eax
f0102bb4:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102bba:	50                   	push   %eax
f0102bbb:	68 00 03 00 00       	push   $0x300
f0102bc0:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102bc6:	50                   	push   %eax
f0102bc7:	e8 cd d4 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102bcc:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102bcf:	c1 e7 0c             	shl    $0xc,%edi
f0102bd2:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102bd7:	eb 17                	jmp    f0102bf0 <mem_init+0x1790>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bd9:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102bdf:	89 f0                	mov    %esi,%eax
f0102be1:	e8 7e de ff ff       	call   f0100a64 <check_va2pa>
f0102be6:	39 c3                	cmp    %eax,%ebx
f0102be8:	75 51                	jne    f0102c3b <mem_init+0x17db>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102bea:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102bf0:	39 fb                	cmp    %edi,%ebx
f0102bf2:	72 e5                	jb     f0102bd9 <mem_init+0x1779>
f0102bf4:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102bf9:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102bfc:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102c02:	89 da                	mov    %ebx,%edx
f0102c04:	89 f0                	mov    %esi,%eax
f0102c06:	e8 59 de ff ff       	call   f0100a64 <check_va2pa>
f0102c0b:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102c0e:	39 c2                	cmp    %eax,%edx
f0102c10:	75 4b                	jne    f0102c5d <mem_init+0x17fd>
f0102c12:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102c18:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102c1e:	75 e2                	jne    f0102c02 <mem_init+0x17a2>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c20:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102c25:	89 f0                	mov    %esi,%eax
f0102c27:	e8 38 de ff ff       	call   f0100a64 <check_va2pa>
f0102c2c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c2f:	75 4e                	jne    f0102c7f <mem_init+0x181f>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c31:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c36:	e9 8f 00 00 00       	jmp    f0102cca <mem_init+0x186a>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102c3b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c3e:	8d 83 74 db fe ff    	lea    -0x1248c(%ebx),%eax
f0102c44:	50                   	push   %eax
f0102c45:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102c4b:	50                   	push   %eax
f0102c4c:	68 05 03 00 00       	push   $0x305
f0102c51:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102c57:	50                   	push   %eax
f0102c58:	e8 3c d4 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c5d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c60:	8d 83 9c db fe ff    	lea    -0x12464(%ebx),%eax
f0102c66:	50                   	push   %eax
f0102c67:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102c6d:	50                   	push   %eax
f0102c6e:	68 09 03 00 00       	push   $0x309
f0102c73:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102c79:	50                   	push   %eax
f0102c7a:	e8 1a d4 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c7f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c82:	8d 83 e4 db fe ff    	lea    -0x1241c(%ebx),%eax
f0102c88:	50                   	push   %eax
f0102c89:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102c8f:	50                   	push   %eax
f0102c90:	68 0a 03 00 00       	push   $0x30a
f0102c95:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102c9b:	50                   	push   %eax
f0102c9c:	e8 f8 d3 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102ca1:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102ca5:	74 52                	je     f0102cf9 <mem_init+0x1899>
	for (i = 0; i < NPDENTRIES; i++) {
f0102ca7:	83 c0 01             	add    $0x1,%eax
f0102caa:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102caf:	0f 87 bb 00 00 00    	ja     f0102d70 <mem_init+0x1910>
		switch (i) {
f0102cb5:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102cba:	72 0e                	jb     f0102cca <mem_init+0x186a>
f0102cbc:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102cc1:	76 de                	jbe    f0102ca1 <mem_init+0x1841>
f0102cc3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102cc8:	74 d7                	je     f0102ca1 <mem_init+0x1841>
			if (i >= PDX(KERNBASE)) {
f0102cca:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102ccf:	77 4a                	ja     f0102d1b <mem_init+0x18bb>
				assert(pgdir[i] == 0);
f0102cd1:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102cd5:	74 d0                	je     f0102ca7 <mem_init+0x1847>
f0102cd7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cda:	8d 83 b6 df fe ff    	lea    -0x1204a(%ebx),%eax
f0102ce0:	50                   	push   %eax
f0102ce1:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102ce7:	50                   	push   %eax
f0102ce8:	68 19 03 00 00       	push   $0x319
f0102ced:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102cf3:	50                   	push   %eax
f0102cf4:	e8 a0 d3 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102cf9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cfc:	8d 83 94 df fe ff    	lea    -0x1206c(%ebx),%eax
f0102d02:	50                   	push   %eax
f0102d03:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102d09:	50                   	push   %eax
f0102d0a:	68 12 03 00 00       	push   $0x312
f0102d0f:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102d15:	50                   	push   %eax
f0102d16:	e8 7e d3 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102d1b:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102d1e:	f6 c2 01             	test   $0x1,%dl
f0102d21:	74 2b                	je     f0102d4e <mem_init+0x18ee>
				assert(pgdir[i] & PTE_W);
f0102d23:	f6 c2 02             	test   $0x2,%dl
f0102d26:	0f 85 7b ff ff ff    	jne    f0102ca7 <mem_init+0x1847>
f0102d2c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d2f:	8d 83 a5 df fe ff    	lea    -0x1205b(%ebx),%eax
f0102d35:	50                   	push   %eax
f0102d36:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102d3c:	50                   	push   %eax
f0102d3d:	68 17 03 00 00       	push   $0x317
f0102d42:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102d48:	50                   	push   %eax
f0102d49:	e8 4b d3 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102d4e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d51:	8d 83 94 df fe ff    	lea    -0x1206c(%ebx),%eax
f0102d57:	50                   	push   %eax
f0102d58:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0102d5e:	50                   	push   %eax
f0102d5f:	68 16 03 00 00       	push   $0x316
f0102d64:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102d6a:	50                   	push   %eax
f0102d6b:	e8 29 d3 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102d70:	83 ec 0c             	sub    $0xc,%esp
f0102d73:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d76:	8d 87 14 dc fe ff    	lea    -0x123ec(%edi),%eax
f0102d7c:	50                   	push   %eax
f0102d7d:	89 fb                	mov    %edi,%ebx
f0102d7f:	e8 ea 04 00 00       	call   f010326e <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102d84:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102d8a:	8b 00                	mov    (%eax),%eax
f0102d8c:	83 c4 10             	add    $0x10,%esp
f0102d8f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d94:	0f 86 44 02 00 00    	jbe    f0102fde <mem_init+0x1b7e>
	return (physaddr_t)kva - KERNBASE;
f0102d9a:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102d9f:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102da2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102da7:	e8 e1 dd ff ff       	call   f0100b8d <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102dac:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102daf:	83 e0 f3             	and    $0xfffffff3,%eax
f0102db2:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102db7:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102dba:	83 ec 0c             	sub    $0xc,%esp
f0102dbd:	6a 00                	push   $0x0
f0102dbf:	e8 a7 e2 ff ff       	call   f010106b <page_alloc>
f0102dc4:	89 c6                	mov    %eax,%esi
f0102dc6:	83 c4 10             	add    $0x10,%esp
f0102dc9:	85 c0                	test   %eax,%eax
f0102dcb:	0f 84 29 02 00 00    	je     f0102ffa <mem_init+0x1b9a>
	assert((pp1 = page_alloc(0)));
f0102dd1:	83 ec 0c             	sub    $0xc,%esp
f0102dd4:	6a 00                	push   $0x0
f0102dd6:	e8 90 e2 ff ff       	call   f010106b <page_alloc>
f0102ddb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102dde:	83 c4 10             	add    $0x10,%esp
f0102de1:	85 c0                	test   %eax,%eax
f0102de3:	0f 84 33 02 00 00    	je     f010301c <mem_init+0x1bbc>
	assert((pp2 = page_alloc(0)));
f0102de9:	83 ec 0c             	sub    $0xc,%esp
f0102dec:	6a 00                	push   $0x0
f0102dee:	e8 78 e2 ff ff       	call   f010106b <page_alloc>
f0102df3:	89 c7                	mov    %eax,%edi
f0102df5:	83 c4 10             	add    $0x10,%esp
f0102df8:	85 c0                	test   %eax,%eax
f0102dfa:	0f 84 3e 02 00 00    	je     f010303e <mem_init+0x1bde>
	page_free(pp0);
f0102e00:	83 ec 0c             	sub    $0xc,%esp
f0102e03:	56                   	push   %esi
f0102e04:	e8 ea e2 ff ff       	call   f01010f3 <page_free>
	return (pp - pages) << PGSHIFT;
f0102e09:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e0c:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102e12:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102e15:	2b 08                	sub    (%eax),%ecx
f0102e17:	89 c8                	mov    %ecx,%eax
f0102e19:	c1 f8 03             	sar    $0x3,%eax
f0102e1c:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e1f:	89 c1                	mov    %eax,%ecx
f0102e21:	c1 e9 0c             	shr    $0xc,%ecx
f0102e24:	83 c4 10             	add    $0x10,%esp
f0102e27:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102e2d:	3b 0a                	cmp    (%edx),%ecx
f0102e2f:	0f 83 2b 02 00 00    	jae    f0103060 <mem_init+0x1c00>
	memset(page2kva(pp1), 1, PGSIZE);
f0102e35:	83 ec 04             	sub    $0x4,%esp
f0102e38:	68 00 10 00 00       	push   $0x1000
f0102e3d:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102e3f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e44:	50                   	push   %eax
f0102e45:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e48:	e8 6a 10 00 00       	call   f0103eb7 <memset>
	return (pp - pages) << PGSHIFT;
f0102e4d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e50:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102e56:	89 f9                	mov    %edi,%ecx
f0102e58:	2b 08                	sub    (%eax),%ecx
f0102e5a:	89 c8                	mov    %ecx,%eax
f0102e5c:	c1 f8 03             	sar    $0x3,%eax
f0102e5f:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e62:	89 c1                	mov    %eax,%ecx
f0102e64:	c1 e9 0c             	shr    $0xc,%ecx
f0102e67:	83 c4 10             	add    $0x10,%esp
f0102e6a:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102e70:	3b 0a                	cmp    (%edx),%ecx
f0102e72:	0f 83 fe 01 00 00    	jae    f0103076 <mem_init+0x1c16>
	memset(page2kva(pp2), 2, PGSIZE);
f0102e78:	83 ec 04             	sub    $0x4,%esp
f0102e7b:	68 00 10 00 00       	push   $0x1000
f0102e80:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102e82:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e87:	50                   	push   %eax
f0102e88:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e8b:	e8 27 10 00 00       	call   f0103eb7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102e90:	6a 02                	push   $0x2
f0102e92:	68 00 10 00 00       	push   $0x1000
f0102e97:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102e9a:	53                   	push   %ebx
f0102e9b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e9e:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102ea4:	ff 30                	pushl  (%eax)
f0102ea6:	e8 1e e5 ff ff       	call   f01013c9 <page_insert>
	assert(pp1->pp_ref == 1);
f0102eab:	83 c4 20             	add    $0x20,%esp
f0102eae:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102eb3:	0f 85 d3 01 00 00    	jne    f010308c <mem_init+0x1c2c>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102eb9:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ec0:	01 01 01 
f0102ec3:	0f 85 e5 01 00 00    	jne    f01030ae <mem_init+0x1c4e>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ec9:	6a 02                	push   $0x2
f0102ecb:	68 00 10 00 00       	push   $0x1000
f0102ed0:	57                   	push   %edi
f0102ed1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ed4:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102eda:	ff 30                	pushl  (%eax)
f0102edc:	e8 e8 e4 ff ff       	call   f01013c9 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ee1:	83 c4 10             	add    $0x10,%esp
f0102ee4:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102eeb:	02 02 02 
f0102eee:	0f 85 dc 01 00 00    	jne    f01030d0 <mem_init+0x1c70>
	assert(pp2->pp_ref == 1);
f0102ef4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102ef9:	0f 85 f3 01 00 00    	jne    f01030f2 <mem_init+0x1c92>
	assert(pp1->pp_ref == 0);
f0102eff:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102f02:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102f07:	0f 85 07 02 00 00    	jne    f0103114 <mem_init+0x1cb4>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102f0d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102f14:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102f17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f1a:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102f20:	89 f9                	mov    %edi,%ecx
f0102f22:	2b 08                	sub    (%eax),%ecx
f0102f24:	89 c8                	mov    %ecx,%eax
f0102f26:	c1 f8 03             	sar    $0x3,%eax
f0102f29:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102f2c:	89 c1                	mov    %eax,%ecx
f0102f2e:	c1 e9 0c             	shr    $0xc,%ecx
f0102f31:	c7 c2 c8 96 11 f0    	mov    $0xf01196c8,%edx
f0102f37:	3b 0a                	cmp    (%edx),%ecx
f0102f39:	0f 83 f7 01 00 00    	jae    f0103136 <mem_init+0x1cd6>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f3f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102f46:	03 03 03 
f0102f49:	0f 85 fd 01 00 00    	jne    f010314c <mem_init+0x1cec>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102f4f:	83 ec 08             	sub    $0x8,%esp
f0102f52:	68 00 10 00 00       	push   $0x1000
f0102f57:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f5a:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102f60:	ff 30                	pushl  (%eax)
f0102f62:	e8 ea e3 ff ff       	call   f0101351 <page_remove>
	assert(pp2->pp_ref == 0);
f0102f67:	83 c4 10             	add    $0x10,%esp
f0102f6a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102f6f:	0f 85 f9 01 00 00    	jne    f010316e <mem_init+0x1d0e>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f75:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102f78:	c7 c0 cc 96 11 f0    	mov    $0xf01196cc,%eax
f0102f7e:	8b 08                	mov    (%eax),%ecx
f0102f80:	8b 11                	mov    (%ecx),%edx
f0102f82:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102f88:	c7 c0 d0 96 11 f0    	mov    $0xf01196d0,%eax
f0102f8e:	89 f7                	mov    %esi,%edi
f0102f90:	2b 38                	sub    (%eax),%edi
f0102f92:	89 f8                	mov    %edi,%eax
f0102f94:	c1 f8 03             	sar    $0x3,%eax
f0102f97:	c1 e0 0c             	shl    $0xc,%eax
f0102f9a:	39 c2                	cmp    %eax,%edx
f0102f9c:	0f 85 ee 01 00 00    	jne    f0103190 <mem_init+0x1d30>
	kern_pgdir[0] = 0;
f0102fa2:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102fa8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102fad:	0f 85 ff 01 00 00    	jne    f01031b2 <mem_init+0x1d52>
	pp0->pp_ref = 0;
f0102fb3:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102fb9:	83 ec 0c             	sub    $0xc,%esp
f0102fbc:	56                   	push   %esi
f0102fbd:	e8 31 e1 ff ff       	call   f01010f3 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102fc2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fc5:	8d 83 a8 dc fe ff    	lea    -0x12358(%ebx),%eax
f0102fcb:	89 04 24             	mov    %eax,(%esp)
f0102fce:	e8 9b 02 00 00       	call   f010326e <cprintf>
}
f0102fd3:	83 c4 10             	add    $0x10,%esp
f0102fd6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fd9:	5b                   	pop    %ebx
f0102fda:	5e                   	pop    %esi
f0102fdb:	5f                   	pop    %edi
f0102fdc:	5d                   	pop    %ebp
f0102fdd:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fde:	50                   	push   %eax
f0102fdf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fe2:	8d 83 f0 d4 fe ff    	lea    -0x12b10(%ebx),%eax
f0102fe8:	50                   	push   %eax
f0102fe9:	68 e0 00 00 00       	push   $0xe0
f0102fee:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0102ff4:	50                   	push   %eax
f0102ff5:	e8 9f d0 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102ffa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ffd:	8d 83 b2 dd fe ff    	lea    -0x1224e(%ebx),%eax
f0103003:	50                   	push   %eax
f0103004:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010300a:	50                   	push   %eax
f010300b:	68 d9 03 00 00       	push   $0x3d9
f0103010:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0103016:	50                   	push   %eax
f0103017:	e8 7d d0 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010301c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010301f:	8d 83 c8 dd fe ff    	lea    -0x12238(%ebx),%eax
f0103025:	50                   	push   %eax
f0103026:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010302c:	50                   	push   %eax
f010302d:	68 da 03 00 00       	push   $0x3da
f0103032:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0103038:	50                   	push   %eax
f0103039:	e8 5b d0 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010303e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103041:	8d 83 de dd fe ff    	lea    -0x12222(%ebx),%eax
f0103047:	50                   	push   %eax
f0103048:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010304e:	50                   	push   %eax
f010304f:	68 db 03 00 00       	push   $0x3db
f0103054:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010305a:	50                   	push   %eax
f010305b:	e8 39 d0 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103060:	50                   	push   %eax
f0103061:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f0103067:	50                   	push   %eax
f0103068:	6a 52                	push   $0x52
f010306a:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0103070:	50                   	push   %eax
f0103071:	e8 23 d0 ff ff       	call   f0100099 <_panic>
f0103076:	50                   	push   %eax
f0103077:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f010307d:	50                   	push   %eax
f010307e:	6a 52                	push   $0x52
f0103080:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0103086:	50                   	push   %eax
f0103087:	e8 0d d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f010308c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010308f:	8d 83 af de fe ff    	lea    -0x12151(%ebx),%eax
f0103095:	50                   	push   %eax
f0103096:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010309c:	50                   	push   %eax
f010309d:	68 e0 03 00 00       	push   $0x3e0
f01030a2:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01030a8:	50                   	push   %eax
f01030a9:	e8 eb cf ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01030ae:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030b1:	8d 83 34 dc fe ff    	lea    -0x123cc(%ebx),%eax
f01030b7:	50                   	push   %eax
f01030b8:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01030be:	50                   	push   %eax
f01030bf:	68 e1 03 00 00       	push   $0x3e1
f01030c4:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01030ca:	50                   	push   %eax
f01030cb:	e8 c9 cf ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01030d0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030d3:	8d 83 58 dc fe ff    	lea    -0x123a8(%ebx),%eax
f01030d9:	50                   	push   %eax
f01030da:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01030e0:	50                   	push   %eax
f01030e1:	68 e3 03 00 00       	push   $0x3e3
f01030e6:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01030ec:	50                   	push   %eax
f01030ed:	e8 a7 cf ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01030f2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030f5:	8d 83 d1 de fe ff    	lea    -0x1212f(%ebx),%eax
f01030fb:	50                   	push   %eax
f01030fc:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0103102:	50                   	push   %eax
f0103103:	68 e4 03 00 00       	push   $0x3e4
f0103108:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010310e:	50                   	push   %eax
f010310f:	e8 85 cf ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0103114:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103117:	8d 83 3b df fe ff    	lea    -0x120c5(%ebx),%eax
f010311d:	50                   	push   %eax
f010311e:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f0103124:	50                   	push   %eax
f0103125:	68 e5 03 00 00       	push   $0x3e5
f010312a:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0103130:	50                   	push   %eax
f0103131:	e8 63 cf ff ff       	call   f0100099 <_panic>
f0103136:	50                   	push   %eax
f0103137:	8d 83 cc d4 fe ff    	lea    -0x12b34(%ebx),%eax
f010313d:	50                   	push   %eax
f010313e:	6a 52                	push   $0x52
f0103140:	8d 83 ed dc fe ff    	lea    -0x12313(%ebx),%eax
f0103146:	50                   	push   %eax
f0103147:	e8 4d cf ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010314c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010314f:	8d 83 7c dc fe ff    	lea    -0x12384(%ebx),%eax
f0103155:	50                   	push   %eax
f0103156:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010315c:	50                   	push   %eax
f010315d:	68 e7 03 00 00       	push   $0x3e7
f0103162:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f0103168:	50                   	push   %eax
f0103169:	e8 2b cf ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010316e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103171:	8d 83 09 df fe ff    	lea    -0x120f7(%ebx),%eax
f0103177:	50                   	push   %eax
f0103178:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f010317e:	50                   	push   %eax
f010317f:	68 e9 03 00 00       	push   $0x3e9
f0103184:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f010318a:	50                   	push   %eax
f010318b:	e8 09 cf ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103190:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103193:	8d 83 c0 d7 fe ff    	lea    -0x12840(%ebx),%eax
f0103199:	50                   	push   %eax
f010319a:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01031a0:	50                   	push   %eax
f01031a1:	68 ec 03 00 00       	push   $0x3ec
f01031a6:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01031ac:	50                   	push   %eax
f01031ad:	e8 e7 ce ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01031b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031b5:	8d 83 c0 de fe ff    	lea    -0x12140(%ebx),%eax
f01031bb:	50                   	push   %eax
f01031bc:	8d 83 07 dd fe ff    	lea    -0x122f9(%ebx),%eax
f01031c2:	50                   	push   %eax
f01031c3:	68 ee 03 00 00       	push   $0x3ee
f01031c8:	8d 83 d4 dc fe ff    	lea    -0x1232c(%ebx),%eax
f01031ce:	50                   	push   %eax
f01031cf:	e8 c5 ce ff ff       	call   f0100099 <_panic>

f01031d4 <tlb_invalidate>:
{
f01031d4:	55                   	push   %ebp
f01031d5:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01031d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031da:	0f 01 38             	invlpg (%eax)
}
f01031dd:	5d                   	pop    %ebp
f01031de:	c3                   	ret    

f01031df <__x86.get_pc_thunk.cx>:
f01031df:	8b 0c 24             	mov    (%esp),%ecx
f01031e2:	c3                   	ret    

f01031e3 <__x86.get_pc_thunk.di>:
f01031e3:	8b 3c 24             	mov    (%esp),%edi
f01031e6:	c3                   	ret    

f01031e7 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01031e7:	55                   	push   %ebp
f01031e8:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01031ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01031ed:	ba 70 00 00 00       	mov    $0x70,%edx
f01031f2:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01031f3:	ba 71 00 00 00       	mov    $0x71,%edx
f01031f8:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01031f9:	0f b6 c0             	movzbl %al,%eax
}
f01031fc:	5d                   	pop    %ebp
f01031fd:	c3                   	ret    

f01031fe <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01031fe:	55                   	push   %ebp
f01031ff:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103201:	8b 45 08             	mov    0x8(%ebp),%eax
f0103204:	ba 70 00 00 00       	mov    $0x70,%edx
f0103209:	ee                   	out    %al,(%dx)
f010320a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010320d:	ba 71 00 00 00       	mov    $0x71,%edx
f0103212:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103213:	5d                   	pop    %ebp
f0103214:	c3                   	ret    

f0103215 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103215:	55                   	push   %ebp
f0103216:	89 e5                	mov    %esp,%ebp
f0103218:	53                   	push   %ebx
f0103219:	83 ec 10             	sub    $0x10,%esp
f010321c:	e8 2e cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103221:	81 c3 eb 40 01 00    	add    $0x140eb,%ebx
	cputchar(ch);
f0103227:	ff 75 08             	pushl  0x8(%ebp)
f010322a:	e8 97 d4 ff ff       	call   f01006c6 <cputchar>
	*cnt++;
}
f010322f:	83 c4 10             	add    $0x10,%esp
f0103232:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103235:	c9                   	leave  
f0103236:	c3                   	ret    

f0103237 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103237:	55                   	push   %ebp
f0103238:	89 e5                	mov    %esp,%ebp
f010323a:	53                   	push   %ebx
f010323b:	83 ec 14             	sub    $0x14,%esp
f010323e:	e8 0c cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103243:	81 c3 c9 40 01 00    	add    $0x140c9,%ebx
	int cnt = 0;
f0103249:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103250:	ff 75 0c             	pushl  0xc(%ebp)
f0103253:	ff 75 08             	pushl  0x8(%ebp)
f0103256:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103259:	50                   	push   %eax
f010325a:	8d 83 09 bf fe ff    	lea    -0x140f7(%ebx),%eax
f0103260:	50                   	push   %eax
f0103261:	e8 98 04 00 00       	call   f01036fe <vprintfmt>
	return cnt;
}
f0103266:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103269:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010326c:	c9                   	leave  
f010326d:	c3                   	ret    

f010326e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010326e:	55                   	push   %ebp
f010326f:	89 e5                	mov    %esp,%ebp
f0103271:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103274:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103277:	50                   	push   %eax
f0103278:	ff 75 08             	pushl  0x8(%ebp)
f010327b:	e8 b7 ff ff ff       	call   f0103237 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103280:	c9                   	leave  
f0103281:	c3                   	ret    

f0103282 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103282:	55                   	push   %ebp
f0103283:	89 e5                	mov    %esp,%ebp
f0103285:	57                   	push   %edi
f0103286:	56                   	push   %esi
f0103287:	53                   	push   %ebx
f0103288:	83 ec 14             	sub    $0x14,%esp
f010328b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010328e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103291:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103294:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103297:	8b 32                	mov    (%edx),%esi
f0103299:	8b 01                	mov    (%ecx),%eax
f010329b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010329e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01032a5:	eb 2f                	jmp    f01032d6 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01032a7:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01032aa:	39 c6                	cmp    %eax,%esi
f01032ac:	7f 49                	jg     f01032f7 <stab_binsearch+0x75>
f01032ae:	0f b6 0a             	movzbl (%edx),%ecx
f01032b1:	83 ea 0c             	sub    $0xc,%edx
f01032b4:	39 f9                	cmp    %edi,%ecx
f01032b6:	75 ef                	jne    f01032a7 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01032b8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01032bb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01032be:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01032c2:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01032c5:	73 35                	jae    f01032fc <stab_binsearch+0x7a>
			*region_left = m;
f01032c7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01032ca:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f01032cc:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01032cf:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01032d6:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01032d9:	7f 4e                	jg     f0103329 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01032db:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01032de:	01 f0                	add    %esi,%eax
f01032e0:	89 c3                	mov    %eax,%ebx
f01032e2:	c1 eb 1f             	shr    $0x1f,%ebx
f01032e5:	01 c3                	add    %eax,%ebx
f01032e7:	d1 fb                	sar    %ebx
f01032e9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01032ec:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01032ef:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01032f3:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01032f5:	eb b3                	jmp    f01032aa <stab_binsearch+0x28>
			l = true_m + 1;
f01032f7:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01032fa:	eb da                	jmp    f01032d6 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01032fc:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01032ff:	76 14                	jbe    f0103315 <stab_binsearch+0x93>
			*region_right = m - 1;
f0103301:	83 e8 01             	sub    $0x1,%eax
f0103304:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103307:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010330a:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f010330c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103313:	eb c1                	jmp    f01032d6 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103315:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103318:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f010331a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010331e:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0103320:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103327:	eb ad                	jmp    f01032d6 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103329:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010332d:	74 16                	je     f0103345 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010332f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103332:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103334:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103337:	8b 0e                	mov    (%esi),%ecx
f0103339:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010333c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010333f:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0103343:	eb 12                	jmp    f0103357 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0103345:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103348:	8b 00                	mov    (%eax),%eax
f010334a:	83 e8 01             	sub    $0x1,%eax
f010334d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103350:	89 07                	mov    %eax,(%edi)
f0103352:	eb 16                	jmp    f010336a <stab_binsearch+0xe8>
		     l--)
f0103354:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0103357:	39 c1                	cmp    %eax,%ecx
f0103359:	7d 0a                	jge    f0103365 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f010335b:	0f b6 1a             	movzbl (%edx),%ebx
f010335e:	83 ea 0c             	sub    $0xc,%edx
f0103361:	39 fb                	cmp    %edi,%ebx
f0103363:	75 ef                	jne    f0103354 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0103365:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103368:	89 07                	mov    %eax,(%edi)
	}
}
f010336a:	83 c4 14             	add    $0x14,%esp
f010336d:	5b                   	pop    %ebx
f010336e:	5e                   	pop    %esi
f010336f:	5f                   	pop    %edi
f0103370:	5d                   	pop    %ebp
f0103371:	c3                   	ret    

f0103372 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103372:	55                   	push   %ebp
f0103373:	89 e5                	mov    %esp,%ebp
f0103375:	57                   	push   %edi
f0103376:	56                   	push   %esi
f0103377:	53                   	push   %ebx
f0103378:	83 ec 3c             	sub    $0x3c,%esp
f010337b:	e8 cf cd ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103380:	81 c3 8c 3f 01 00    	add    $0x13f8c,%ebx
f0103386:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103389:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010338c:	8d 83 c4 df fe ff    	lea    -0x1203c(%ebx),%eax
f0103392:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0103394:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010339b:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f010339e:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01033a5:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01033a8:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01033af:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01033b5:	0f 86 37 01 00 00    	jbe    f01034f2 <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01033bb:	c7 c0 69 bf 10 f0    	mov    $0xf010bf69,%eax
f01033c1:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f01033c7:	0f 86 04 02 00 00    	jbe    f01035d1 <debuginfo_eip+0x25f>
f01033cd:	c7 c0 b7 dd 10 f0    	mov    $0xf010ddb7,%eax
f01033d3:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01033d7:	0f 85 fb 01 00 00    	jne    f01035d8 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01033dd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01033e4:	c7 c0 e8 54 10 f0    	mov    $0xf01054e8,%eax
f01033ea:	c7 c2 68 bf 10 f0    	mov    $0xf010bf68,%edx
f01033f0:	29 c2                	sub    %eax,%edx
f01033f2:	c1 fa 02             	sar    $0x2,%edx
f01033f5:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01033fb:	83 ea 01             	sub    $0x1,%edx
f01033fe:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103401:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103404:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103407:	83 ec 08             	sub    $0x8,%esp
f010340a:	57                   	push   %edi
f010340b:	6a 64                	push   $0x64
f010340d:	e8 70 fe ff ff       	call   f0103282 <stab_binsearch>
	if (lfile == 0)
f0103412:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103415:	83 c4 10             	add    $0x10,%esp
f0103418:	85 c0                	test   %eax,%eax
f010341a:	0f 84 bf 01 00 00    	je     f01035df <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103420:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103423:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103426:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103429:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010342c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010342f:	83 ec 08             	sub    $0x8,%esp
f0103432:	57                   	push   %edi
f0103433:	6a 24                	push   $0x24
f0103435:	c7 c0 e8 54 10 f0    	mov    $0xf01054e8,%eax
f010343b:	e8 42 fe ff ff       	call   f0103282 <stab_binsearch>

	if (lfun <= rfun) {
f0103440:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103443:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103446:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0103449:	83 c4 10             	add    $0x10,%esp
f010344c:	39 c8                	cmp    %ecx,%eax
f010344e:	0f 8f b6 00 00 00    	jg     f010350a <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103454:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103457:	c7 c1 e8 54 10 f0    	mov    $0xf01054e8,%ecx
f010345d:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0103460:	8b 11                	mov    (%ecx),%edx
f0103462:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0103465:	c7 c2 b7 dd 10 f0    	mov    $0xf010ddb7,%edx
f010346b:	81 ea 69 bf 10 f0    	sub    $0xf010bf69,%edx
f0103471:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0103474:	73 0c                	jae    f0103482 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103476:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103479:	81 c2 69 bf 10 f0    	add    $0xf010bf69,%edx
f010347f:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103482:	8b 51 08             	mov    0x8(%ecx),%edx
f0103485:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103488:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f010348a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010348d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103490:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103493:	83 ec 08             	sub    $0x8,%esp
f0103496:	6a 3a                	push   $0x3a
f0103498:	ff 76 08             	pushl  0x8(%esi)
f010349b:	e8 fb 09 00 00       	call   f0103e9b <strfind>
f01034a0:	2b 46 08             	sub    0x8(%esi),%eax
f01034a3:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01034a6:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01034a9:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01034ac:	83 c4 08             	add    $0x8,%esp
f01034af:	57                   	push   %edi
f01034b0:	6a 44                	push   $0x44
f01034b2:	c7 c0 e8 54 10 f0    	mov    $0xf01054e8,%eax
f01034b8:	e8 c5 fd ff ff       	call   f0103282 <stab_binsearch>
    if (lline <= rline) {
f01034bd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01034c0:	83 c4 10             	add    $0x10,%esp
f01034c3:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01034c6:	0f 8f 1a 01 00 00    	jg     f01035e6 <debuginfo_eip+0x274>
        info->eip_line = stabs[lline].n_desc;
f01034cc:	89 d0                	mov    %edx,%eax
f01034ce:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01034d1:	c1 e2 02             	shl    $0x2,%edx
f01034d4:	c7 c1 e8 54 10 f0    	mov    $0xf01054e8,%ecx
f01034da:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f01034df:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01034e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034e5:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f01034e9:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f01034ed:	89 75 0c             	mov    %esi,0xc(%ebp)
f01034f0:	eb 36                	jmp    f0103528 <debuginfo_eip+0x1b6>
  	        panic("User address");
f01034f2:	83 ec 04             	sub    $0x4,%esp
f01034f5:	8d 83 ce df fe ff    	lea    -0x12032(%ebx),%eax
f01034fb:	50                   	push   %eax
f01034fc:	6a 7f                	push   $0x7f
f01034fe:	8d 83 db df fe ff    	lea    -0x12025(%ebx),%eax
f0103504:	50                   	push   %eax
f0103505:	e8 8f cb ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f010350a:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010350d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103510:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103513:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103516:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103519:	e9 75 ff ff ff       	jmp    f0103493 <debuginfo_eip+0x121>
f010351e:	83 e8 01             	sub    $0x1,%eax
f0103521:	83 ea 0c             	sub    $0xc,%edx
f0103524:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103528:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f010352b:	39 c7                	cmp    %eax,%edi
f010352d:	7f 24                	jg     f0103553 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f010352f:	0f b6 0a             	movzbl (%edx),%ecx
f0103532:	80 f9 84             	cmp    $0x84,%cl
f0103535:	74 46                	je     f010357d <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103537:	80 f9 64             	cmp    $0x64,%cl
f010353a:	75 e2                	jne    f010351e <debuginfo_eip+0x1ac>
f010353c:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0103540:	74 dc                	je     f010351e <debuginfo_eip+0x1ac>
f0103542:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103545:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103549:	74 3b                	je     f0103586 <debuginfo_eip+0x214>
f010354b:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010354e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103551:	eb 33                	jmp    f0103586 <debuginfo_eip+0x214>
f0103553:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103556:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103559:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010355c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0103561:	39 fa                	cmp    %edi,%edx
f0103563:	0f 8d 89 00 00 00    	jge    f01035f2 <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0103569:	83 c2 01             	add    $0x1,%edx
f010356c:	89 d0                	mov    %edx,%eax
f010356e:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0103571:	c7 c2 e8 54 10 f0    	mov    $0xf01054e8,%edx
f0103577:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f010357b:	eb 3b                	jmp    f01035b8 <debuginfo_eip+0x246>
f010357d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103580:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103584:	75 26                	jne    f01035ac <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103586:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103589:	c7 c0 e8 54 10 f0    	mov    $0xf01054e8,%eax
f010358f:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0103592:	c7 c0 b7 dd 10 f0    	mov    $0xf010ddb7,%eax
f0103598:	81 e8 69 bf 10 f0    	sub    $0xf010bf69,%eax
f010359e:	39 c2                	cmp    %eax,%edx
f01035a0:	73 b4                	jae    f0103556 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01035a2:	81 c2 69 bf 10 f0    	add    $0xf010bf69,%edx
f01035a8:	89 16                	mov    %edx,(%esi)
f01035aa:	eb aa                	jmp    f0103556 <debuginfo_eip+0x1e4>
f01035ac:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01035af:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01035b2:	eb d2                	jmp    f0103586 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f01035b4:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f01035b8:	39 c7                	cmp    %eax,%edi
f01035ba:	7e 31                	jle    f01035ed <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01035bc:	0f b6 0a             	movzbl (%edx),%ecx
f01035bf:	83 c0 01             	add    $0x1,%eax
f01035c2:	83 c2 0c             	add    $0xc,%edx
f01035c5:	80 f9 a0             	cmp    $0xa0,%cl
f01035c8:	74 ea                	je     f01035b4 <debuginfo_eip+0x242>
	return 0;
f01035ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01035cf:	eb 21                	jmp    f01035f2 <debuginfo_eip+0x280>
		return -1;
f01035d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035d6:	eb 1a                	jmp    f01035f2 <debuginfo_eip+0x280>
f01035d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035dd:	eb 13                	jmp    f01035f2 <debuginfo_eip+0x280>
		return -1;
f01035df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035e4:	eb 0c                	jmp    f01035f2 <debuginfo_eip+0x280>
        return -1;
f01035e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035eb:	eb 05                	jmp    f01035f2 <debuginfo_eip+0x280>
	return 0;
f01035ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01035f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01035f5:	5b                   	pop    %ebx
f01035f6:	5e                   	pop    %esi
f01035f7:	5f                   	pop    %edi
f01035f8:	5d                   	pop    %ebp
f01035f9:	c3                   	ret    

f01035fa <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01035fa:	55                   	push   %ebp
f01035fb:	89 e5                	mov    %esp,%ebp
f01035fd:	57                   	push   %edi
f01035fe:	56                   	push   %esi
f01035ff:	53                   	push   %ebx
f0103600:	83 ec 2c             	sub    $0x2c,%esp
f0103603:	e8 d7 fb ff ff       	call   f01031df <__x86.get_pc_thunk.cx>
f0103608:	81 c1 04 3d 01 00    	add    $0x13d04,%ecx
f010360e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103611:	89 c7                	mov    %eax,%edi
f0103613:	89 d6                	mov    %edx,%esi
f0103615:	8b 45 08             	mov    0x8(%ebp),%eax
f0103618:	8b 55 0c             	mov    0xc(%ebp),%edx
f010361b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010361e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103621:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103624:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103629:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f010362c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010362f:	39 d3                	cmp    %edx,%ebx
f0103631:	72 09                	jb     f010363c <printnum+0x42>
f0103633:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103636:	0f 87 83 00 00 00    	ja     f01036bf <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010363c:	83 ec 0c             	sub    $0xc,%esp
f010363f:	ff 75 18             	pushl  0x18(%ebp)
f0103642:	8b 45 14             	mov    0x14(%ebp),%eax
f0103645:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103648:	53                   	push   %ebx
f0103649:	ff 75 10             	pushl  0x10(%ebp)
f010364c:	83 ec 08             	sub    $0x8,%esp
f010364f:	ff 75 dc             	pushl  -0x24(%ebp)
f0103652:	ff 75 d8             	pushl  -0x28(%ebp)
f0103655:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103658:	ff 75 d0             	pushl  -0x30(%ebp)
f010365b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010365e:	e8 5d 0a 00 00       	call   f01040c0 <__udivdi3>
f0103663:	83 c4 18             	add    $0x18,%esp
f0103666:	52                   	push   %edx
f0103667:	50                   	push   %eax
f0103668:	89 f2                	mov    %esi,%edx
f010366a:	89 f8                	mov    %edi,%eax
f010366c:	e8 89 ff ff ff       	call   f01035fa <printnum>
f0103671:	83 c4 20             	add    $0x20,%esp
f0103674:	eb 13                	jmp    f0103689 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103676:	83 ec 08             	sub    $0x8,%esp
f0103679:	56                   	push   %esi
f010367a:	ff 75 18             	pushl  0x18(%ebp)
f010367d:	ff d7                	call   *%edi
f010367f:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103682:	83 eb 01             	sub    $0x1,%ebx
f0103685:	85 db                	test   %ebx,%ebx
f0103687:	7f ed                	jg     f0103676 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103689:	83 ec 08             	sub    $0x8,%esp
f010368c:	56                   	push   %esi
f010368d:	83 ec 04             	sub    $0x4,%esp
f0103690:	ff 75 dc             	pushl  -0x24(%ebp)
f0103693:	ff 75 d8             	pushl  -0x28(%ebp)
f0103696:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103699:	ff 75 d0             	pushl  -0x30(%ebp)
f010369c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010369f:	89 f3                	mov    %esi,%ebx
f01036a1:	e8 3a 0b 00 00       	call   f01041e0 <__umoddi3>
f01036a6:	83 c4 14             	add    $0x14,%esp
f01036a9:	0f be 84 06 e9 df fe 	movsbl -0x12017(%esi,%eax,1),%eax
f01036b0:	ff 
f01036b1:	50                   	push   %eax
f01036b2:	ff d7                	call   *%edi
}
f01036b4:	83 c4 10             	add    $0x10,%esp
f01036b7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01036ba:	5b                   	pop    %ebx
f01036bb:	5e                   	pop    %esi
f01036bc:	5f                   	pop    %edi
f01036bd:	5d                   	pop    %ebp
f01036be:	c3                   	ret    
f01036bf:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01036c2:	eb be                	jmp    f0103682 <printnum+0x88>

f01036c4 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01036c4:	55                   	push   %ebp
f01036c5:	89 e5                	mov    %esp,%ebp
f01036c7:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01036ca:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01036ce:	8b 10                	mov    (%eax),%edx
f01036d0:	3b 50 04             	cmp    0x4(%eax),%edx
f01036d3:	73 0a                	jae    f01036df <sprintputch+0x1b>
		*b->buf++ = ch;
f01036d5:	8d 4a 01             	lea    0x1(%edx),%ecx
f01036d8:	89 08                	mov    %ecx,(%eax)
f01036da:	8b 45 08             	mov    0x8(%ebp),%eax
f01036dd:	88 02                	mov    %al,(%edx)
}
f01036df:	5d                   	pop    %ebp
f01036e0:	c3                   	ret    

f01036e1 <printfmt>:
{
f01036e1:	55                   	push   %ebp
f01036e2:	89 e5                	mov    %esp,%ebp
f01036e4:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01036e7:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01036ea:	50                   	push   %eax
f01036eb:	ff 75 10             	pushl  0x10(%ebp)
f01036ee:	ff 75 0c             	pushl  0xc(%ebp)
f01036f1:	ff 75 08             	pushl  0x8(%ebp)
f01036f4:	e8 05 00 00 00       	call   f01036fe <vprintfmt>
}
f01036f9:	83 c4 10             	add    $0x10,%esp
f01036fc:	c9                   	leave  
f01036fd:	c3                   	ret    

f01036fe <vprintfmt>:
{
f01036fe:	55                   	push   %ebp
f01036ff:	89 e5                	mov    %esp,%ebp
f0103701:	57                   	push   %edi
f0103702:	56                   	push   %esi
f0103703:	53                   	push   %ebx
f0103704:	83 ec 2c             	sub    $0x2c,%esp
f0103707:	e8 43 ca ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010370c:	81 c3 00 3c 01 00    	add    $0x13c00,%ebx
f0103712:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103715:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103718:	e9 fb 03 00 00       	jmp    f0103b18 <.L35+0x48>
		padc = ' ';
f010371d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0103721:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0103728:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010372f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0103736:	b9 00 00 00 00       	mov    $0x0,%ecx
f010373b:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010373e:	8d 47 01             	lea    0x1(%edi),%eax
f0103741:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103744:	0f b6 17             	movzbl (%edi),%edx
f0103747:	8d 42 dd             	lea    -0x23(%edx),%eax
f010374a:	3c 55                	cmp    $0x55,%al
f010374c:	0f 87 4e 04 00 00    	ja     f0103ba0 <.L22>
f0103752:	0f b6 c0             	movzbl %al,%eax
f0103755:	89 d9                	mov    %ebx,%ecx
f0103757:	03 8c 83 74 e0 fe ff 	add    -0x11f8c(%ebx,%eax,4),%ecx
f010375e:	ff e1                	jmp    *%ecx

f0103760 <.L71>:
f0103760:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0103763:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0103767:	eb d5                	jmp    f010373e <vprintfmt+0x40>

f0103769 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0103769:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010376c:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103770:	eb cc                	jmp    f010373e <vprintfmt+0x40>

f0103772 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0103772:	0f b6 d2             	movzbl %dl,%edx
f0103775:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0103778:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010377d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103780:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103784:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0103787:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010378a:	83 f9 09             	cmp    $0x9,%ecx
f010378d:	77 55                	ja     f01037e4 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f010378f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103792:	eb e9                	jmp    f010377d <.L29+0xb>

f0103794 <.L26>:
			precision = va_arg(ap, int);
f0103794:	8b 45 14             	mov    0x14(%ebp),%eax
f0103797:	8b 00                	mov    (%eax),%eax
f0103799:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010379c:	8b 45 14             	mov    0x14(%ebp),%eax
f010379f:	8d 40 04             	lea    0x4(%eax),%eax
f01037a2:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01037a5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01037a8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01037ac:	79 90                	jns    f010373e <vprintfmt+0x40>
				width = precision, precision = -1;
f01037ae:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01037b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01037b4:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f01037bb:	eb 81                	jmp    f010373e <vprintfmt+0x40>

f01037bd <.L27>:
f01037bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037c0:	85 c0                	test   %eax,%eax
f01037c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01037c7:	0f 49 d0             	cmovns %eax,%edx
f01037ca:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01037cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01037d0:	e9 69 ff ff ff       	jmp    f010373e <vprintfmt+0x40>

f01037d5 <.L23>:
f01037d5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01037d8:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01037df:	e9 5a ff ff ff       	jmp    f010373e <vprintfmt+0x40>
f01037e4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01037e7:	eb bf                	jmp    f01037a8 <.L26+0x14>

f01037e9 <.L33>:
			lflag++;
f01037e9:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01037ed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f01037f0:	e9 49 ff ff ff       	jmp    f010373e <vprintfmt+0x40>

f01037f5 <.L30>:
			putch(va_arg(ap, int), putdat);
f01037f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01037f8:	8d 78 04             	lea    0x4(%eax),%edi
f01037fb:	83 ec 08             	sub    $0x8,%esp
f01037fe:	56                   	push   %esi
f01037ff:	ff 30                	pushl  (%eax)
f0103801:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103804:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103807:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010380a:	e9 06 03 00 00       	jmp    f0103b15 <.L35+0x45>

f010380f <.L32>:
			err = va_arg(ap, int);
f010380f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103812:	8d 78 04             	lea    0x4(%eax),%edi
f0103815:	8b 00                	mov    (%eax),%eax
f0103817:	99                   	cltd   
f0103818:	31 d0                	xor    %edx,%eax
f010381a:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010381c:	83 f8 06             	cmp    $0x6,%eax
f010381f:	7f 27                	jg     f0103848 <.L32+0x39>
f0103821:	8b 94 83 38 1d 00 00 	mov    0x1d38(%ebx,%eax,4),%edx
f0103828:	85 d2                	test   %edx,%edx
f010382a:	74 1c                	je     f0103848 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f010382c:	52                   	push   %edx
f010382d:	8d 83 19 dd fe ff    	lea    -0x122e7(%ebx),%eax
f0103833:	50                   	push   %eax
f0103834:	56                   	push   %esi
f0103835:	ff 75 08             	pushl  0x8(%ebp)
f0103838:	e8 a4 fe ff ff       	call   f01036e1 <printfmt>
f010383d:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103840:	89 7d 14             	mov    %edi,0x14(%ebp)
f0103843:	e9 cd 02 00 00       	jmp    f0103b15 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103848:	50                   	push   %eax
f0103849:	8d 83 01 e0 fe ff    	lea    -0x11fff(%ebx),%eax
f010384f:	50                   	push   %eax
f0103850:	56                   	push   %esi
f0103851:	ff 75 08             	pushl  0x8(%ebp)
f0103854:	e8 88 fe ff ff       	call   f01036e1 <printfmt>
f0103859:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010385c:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010385f:	e9 b1 02 00 00       	jmp    f0103b15 <.L35+0x45>

f0103864 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0103864:	8b 45 14             	mov    0x14(%ebp),%eax
f0103867:	83 c0 04             	add    $0x4,%eax
f010386a:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010386d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103870:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103872:	85 ff                	test   %edi,%edi
f0103874:	8d 83 fa df fe ff    	lea    -0x12006(%ebx),%eax
f010387a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010387d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103881:	0f 8e b5 00 00 00    	jle    f010393c <.L36+0xd8>
f0103887:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010388b:	75 08                	jne    f0103895 <.L36+0x31>
f010388d:	89 75 0c             	mov    %esi,0xc(%ebp)
f0103890:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103893:	eb 6d                	jmp    f0103902 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103895:	83 ec 08             	sub    $0x8,%esp
f0103898:	ff 75 cc             	pushl  -0x34(%ebp)
f010389b:	57                   	push   %edi
f010389c:	e8 b6 04 00 00       	call   f0103d57 <strnlen>
f01038a1:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01038a4:	29 c2                	sub    %eax,%edx
f01038a6:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01038a9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01038ac:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01038b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01038b3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01038b6:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01038b8:	eb 10                	jmp    f01038ca <.L36+0x66>
					putch(padc, putdat);
f01038ba:	83 ec 08             	sub    $0x8,%esp
f01038bd:	56                   	push   %esi
f01038be:	ff 75 e0             	pushl  -0x20(%ebp)
f01038c1:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01038c4:	83 ef 01             	sub    $0x1,%edi
f01038c7:	83 c4 10             	add    $0x10,%esp
f01038ca:	85 ff                	test   %edi,%edi
f01038cc:	7f ec                	jg     f01038ba <.L36+0x56>
f01038ce:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01038d1:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01038d4:	85 d2                	test   %edx,%edx
f01038d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01038db:	0f 49 c2             	cmovns %edx,%eax
f01038de:	29 c2                	sub    %eax,%edx
f01038e0:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01038e3:	89 75 0c             	mov    %esi,0xc(%ebp)
f01038e6:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01038e9:	eb 17                	jmp    f0103902 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f01038eb:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01038ef:	75 30                	jne    f0103921 <.L36+0xbd>
					putch(ch, putdat);
f01038f1:	83 ec 08             	sub    $0x8,%esp
f01038f4:	ff 75 0c             	pushl  0xc(%ebp)
f01038f7:	50                   	push   %eax
f01038f8:	ff 55 08             	call   *0x8(%ebp)
f01038fb:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01038fe:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0103902:	83 c7 01             	add    $0x1,%edi
f0103905:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0103909:	0f be c2             	movsbl %dl,%eax
f010390c:	85 c0                	test   %eax,%eax
f010390e:	74 52                	je     f0103962 <.L36+0xfe>
f0103910:	85 f6                	test   %esi,%esi
f0103912:	78 d7                	js     f01038eb <.L36+0x87>
f0103914:	83 ee 01             	sub    $0x1,%esi
f0103917:	79 d2                	jns    f01038eb <.L36+0x87>
f0103919:	8b 75 0c             	mov    0xc(%ebp),%esi
f010391c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010391f:	eb 32                	jmp    f0103953 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0103921:	0f be d2             	movsbl %dl,%edx
f0103924:	83 ea 20             	sub    $0x20,%edx
f0103927:	83 fa 5e             	cmp    $0x5e,%edx
f010392a:	76 c5                	jbe    f01038f1 <.L36+0x8d>
					putch('?', putdat);
f010392c:	83 ec 08             	sub    $0x8,%esp
f010392f:	ff 75 0c             	pushl  0xc(%ebp)
f0103932:	6a 3f                	push   $0x3f
f0103934:	ff 55 08             	call   *0x8(%ebp)
f0103937:	83 c4 10             	add    $0x10,%esp
f010393a:	eb c2                	jmp    f01038fe <.L36+0x9a>
f010393c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010393f:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0103942:	eb be                	jmp    f0103902 <.L36+0x9e>
				putch(' ', putdat);
f0103944:	83 ec 08             	sub    $0x8,%esp
f0103947:	56                   	push   %esi
f0103948:	6a 20                	push   $0x20
f010394a:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010394d:	83 ef 01             	sub    $0x1,%edi
f0103950:	83 c4 10             	add    $0x10,%esp
f0103953:	85 ff                	test   %edi,%edi
f0103955:	7f ed                	jg     f0103944 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0103957:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010395a:	89 45 14             	mov    %eax,0x14(%ebp)
f010395d:	e9 b3 01 00 00       	jmp    f0103b15 <.L35+0x45>
f0103962:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103965:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103968:	eb e9                	jmp    f0103953 <.L36+0xef>

f010396a <.L31>:
f010396a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010396d:	83 f9 01             	cmp    $0x1,%ecx
f0103970:	7e 40                	jle    f01039b2 <.L31+0x48>
		return va_arg(*ap, long long);
f0103972:	8b 45 14             	mov    0x14(%ebp),%eax
f0103975:	8b 50 04             	mov    0x4(%eax),%edx
f0103978:	8b 00                	mov    (%eax),%eax
f010397a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010397d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103980:	8b 45 14             	mov    0x14(%ebp),%eax
f0103983:	8d 40 08             	lea    0x8(%eax),%eax
f0103986:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103989:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010398d:	79 55                	jns    f01039e4 <.L31+0x7a>
				putch('-', putdat);
f010398f:	83 ec 08             	sub    $0x8,%esp
f0103992:	56                   	push   %esi
f0103993:	6a 2d                	push   $0x2d
f0103995:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103998:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010399b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010399e:	f7 da                	neg    %edx
f01039a0:	83 d1 00             	adc    $0x0,%ecx
f01039a3:	f7 d9                	neg    %ecx
f01039a5:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01039a8:	b8 0a 00 00 00       	mov    $0xa,%eax
f01039ad:	e9 48 01 00 00       	jmp    f0103afa <.L35+0x2a>
	else if (lflag)
f01039b2:	85 c9                	test   %ecx,%ecx
f01039b4:	75 17                	jne    f01039cd <.L31+0x63>
		return va_arg(*ap, int);
f01039b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01039b9:	8b 00                	mov    (%eax),%eax
f01039bb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039be:	99                   	cltd   
f01039bf:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01039c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01039c5:	8d 40 04             	lea    0x4(%eax),%eax
f01039c8:	89 45 14             	mov    %eax,0x14(%ebp)
f01039cb:	eb bc                	jmp    f0103989 <.L31+0x1f>
		return va_arg(*ap, long);
f01039cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01039d0:	8b 00                	mov    (%eax),%eax
f01039d2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039d5:	99                   	cltd   
f01039d6:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01039d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01039dc:	8d 40 04             	lea    0x4(%eax),%eax
f01039df:	89 45 14             	mov    %eax,0x14(%ebp)
f01039e2:	eb a5                	jmp    f0103989 <.L31+0x1f>
			num = getint(&ap, lflag);
f01039e4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01039e7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f01039ea:	b8 0a 00 00 00       	mov    $0xa,%eax
f01039ef:	e9 06 01 00 00       	jmp    f0103afa <.L35+0x2a>

f01039f4 <.L37>:
f01039f4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01039f7:	83 f9 01             	cmp    $0x1,%ecx
f01039fa:	7e 18                	jle    f0103a14 <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f01039fc:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ff:	8b 10                	mov    (%eax),%edx
f0103a01:	8b 48 04             	mov    0x4(%eax),%ecx
f0103a04:	8d 40 08             	lea    0x8(%eax),%eax
f0103a07:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103a0a:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a0f:	e9 e6 00 00 00       	jmp    f0103afa <.L35+0x2a>
	else if (lflag)
f0103a14:	85 c9                	test   %ecx,%ecx
f0103a16:	75 1a                	jne    f0103a32 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0103a18:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a1b:	8b 10                	mov    (%eax),%edx
f0103a1d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a22:	8d 40 04             	lea    0x4(%eax),%eax
f0103a25:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103a28:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a2d:	e9 c8 00 00 00       	jmp    f0103afa <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103a32:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a35:	8b 10                	mov    (%eax),%edx
f0103a37:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a3c:	8d 40 04             	lea    0x4(%eax),%eax
f0103a3f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103a42:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103a47:	e9 ae 00 00 00       	jmp    f0103afa <.L35+0x2a>

f0103a4c <.L34>:
f0103a4c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103a4f:	83 f9 01             	cmp    $0x1,%ecx
f0103a52:	7e 3d                	jle    f0103a91 <.L34+0x45>
		return va_arg(*ap, long long);
f0103a54:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a57:	8b 50 04             	mov    0x4(%eax),%edx
f0103a5a:	8b 00                	mov    (%eax),%eax
f0103a5c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a5f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103a62:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a65:	8d 40 08             	lea    0x8(%eax),%eax
f0103a68:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0103a6b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103a6f:	79 52                	jns    f0103ac3 <.L34+0x77>
				putch('-', putdat);
f0103a71:	83 ec 08             	sub    $0x8,%esp
f0103a74:	56                   	push   %esi
f0103a75:	6a 2d                	push   $0x2d
f0103a77:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103a7a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103a7d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103a80:	f7 da                	neg    %edx
f0103a82:	83 d1 00             	adc    $0x0,%ecx
f0103a85:	f7 d9                	neg    %ecx
f0103a87:	83 c4 10             	add    $0x10,%esp
			base = 8;
f0103a8a:	b8 08 00 00 00       	mov    $0x8,%eax
f0103a8f:	eb 69                	jmp    f0103afa <.L35+0x2a>
	else if (lflag)
f0103a91:	85 c9                	test   %ecx,%ecx
f0103a93:	75 17                	jne    f0103aac <.L34+0x60>
		return va_arg(*ap, int);
f0103a95:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a98:	8b 00                	mov    (%eax),%eax
f0103a9a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103a9d:	99                   	cltd   
f0103a9e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103aa1:	8b 45 14             	mov    0x14(%ebp),%eax
f0103aa4:	8d 40 04             	lea    0x4(%eax),%eax
f0103aa7:	89 45 14             	mov    %eax,0x14(%ebp)
f0103aaa:	eb bf                	jmp    f0103a6b <.L34+0x1f>
		return va_arg(*ap, long);
f0103aac:	8b 45 14             	mov    0x14(%ebp),%eax
f0103aaf:	8b 00                	mov    (%eax),%eax
f0103ab1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ab4:	99                   	cltd   
f0103ab5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103ab8:	8b 45 14             	mov    0x14(%ebp),%eax
f0103abb:	8d 40 04             	lea    0x4(%eax),%eax
f0103abe:	89 45 14             	mov    %eax,0x14(%ebp)
f0103ac1:	eb a8                	jmp    f0103a6b <.L34+0x1f>
			num = getint(&ap, lflag);
f0103ac3:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103ac6:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 8;
f0103ac9:	b8 08 00 00 00       	mov    $0x8,%eax
f0103ace:	eb 2a                	jmp    f0103afa <.L35+0x2a>

f0103ad0 <.L35>:
			putch('0', putdat);
f0103ad0:	83 ec 08             	sub    $0x8,%esp
f0103ad3:	56                   	push   %esi
f0103ad4:	6a 30                	push   $0x30
f0103ad6:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103ad9:	83 c4 08             	add    $0x8,%esp
f0103adc:	56                   	push   %esi
f0103add:	6a 78                	push   $0x78
f0103adf:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0103ae2:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ae5:	8b 10                	mov    (%eax),%edx
f0103ae7:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0103aec:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103aef:	8d 40 04             	lea    0x4(%eax),%eax
f0103af2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103af5:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103afa:	83 ec 0c             	sub    $0xc,%esp
f0103afd:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103b01:	57                   	push   %edi
f0103b02:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b05:	50                   	push   %eax
f0103b06:	51                   	push   %ecx
f0103b07:	52                   	push   %edx
f0103b08:	89 f2                	mov    %esi,%edx
f0103b0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b0d:	e8 e8 fa ff ff       	call   f01035fa <printnum>
			break;
f0103b12:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0103b15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103b18:	83 c7 01             	add    $0x1,%edi
f0103b1b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103b1f:	83 f8 25             	cmp    $0x25,%eax
f0103b22:	0f 84 f5 fb ff ff    	je     f010371d <vprintfmt+0x1f>
			if (ch == '\0')
f0103b28:	85 c0                	test   %eax,%eax
f0103b2a:	0f 84 91 00 00 00    	je     f0103bc1 <.L22+0x21>
			putch(ch, putdat);
f0103b30:	83 ec 08             	sub    $0x8,%esp
f0103b33:	56                   	push   %esi
f0103b34:	50                   	push   %eax
f0103b35:	ff 55 08             	call   *0x8(%ebp)
f0103b38:	83 c4 10             	add    $0x10,%esp
f0103b3b:	eb db                	jmp    f0103b18 <.L35+0x48>

f0103b3d <.L38>:
f0103b3d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0103b40:	83 f9 01             	cmp    $0x1,%ecx
f0103b43:	7e 15                	jle    f0103b5a <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0103b45:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b48:	8b 10                	mov    (%eax),%edx
f0103b4a:	8b 48 04             	mov    0x4(%eax),%ecx
f0103b4d:	8d 40 08             	lea    0x8(%eax),%eax
f0103b50:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103b53:	b8 10 00 00 00       	mov    $0x10,%eax
f0103b58:	eb a0                	jmp    f0103afa <.L35+0x2a>
	else if (lflag)
f0103b5a:	85 c9                	test   %ecx,%ecx
f0103b5c:	75 17                	jne    f0103b75 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0103b5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b61:	8b 10                	mov    (%eax),%edx
f0103b63:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103b68:	8d 40 04             	lea    0x4(%eax),%eax
f0103b6b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103b6e:	b8 10 00 00 00       	mov    $0x10,%eax
f0103b73:	eb 85                	jmp    f0103afa <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0103b75:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b78:	8b 10                	mov    (%eax),%edx
f0103b7a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103b7f:	8d 40 04             	lea    0x4(%eax),%eax
f0103b82:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103b85:	b8 10 00 00 00       	mov    $0x10,%eax
f0103b8a:	e9 6b ff ff ff       	jmp    f0103afa <.L35+0x2a>

f0103b8f <.L25>:
			putch(ch, putdat);
f0103b8f:	83 ec 08             	sub    $0x8,%esp
f0103b92:	56                   	push   %esi
f0103b93:	6a 25                	push   $0x25
f0103b95:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103b98:	83 c4 10             	add    $0x10,%esp
f0103b9b:	e9 75 ff ff ff       	jmp    f0103b15 <.L35+0x45>

f0103ba0 <.L22>:
			putch('%', putdat);
f0103ba0:	83 ec 08             	sub    $0x8,%esp
f0103ba3:	56                   	push   %esi
f0103ba4:	6a 25                	push   $0x25
f0103ba6:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103ba9:	83 c4 10             	add    $0x10,%esp
f0103bac:	89 f8                	mov    %edi,%eax
f0103bae:	eb 03                	jmp    f0103bb3 <.L22+0x13>
f0103bb0:	83 e8 01             	sub    $0x1,%eax
f0103bb3:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103bb7:	75 f7                	jne    f0103bb0 <.L22+0x10>
f0103bb9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103bbc:	e9 54 ff ff ff       	jmp    f0103b15 <.L35+0x45>
}
f0103bc1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bc4:	5b                   	pop    %ebx
f0103bc5:	5e                   	pop    %esi
f0103bc6:	5f                   	pop    %edi
f0103bc7:	5d                   	pop    %ebp
f0103bc8:	c3                   	ret    

f0103bc9 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103bc9:	55                   	push   %ebp
f0103bca:	89 e5                	mov    %esp,%ebp
f0103bcc:	53                   	push   %ebx
f0103bcd:	83 ec 14             	sub    $0x14,%esp
f0103bd0:	e8 7a c5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103bd5:	81 c3 37 37 01 00    	add    $0x13737,%ebx
f0103bdb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bde:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103be1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103be4:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103be8:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103beb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103bf2:	85 c0                	test   %eax,%eax
f0103bf4:	74 2b                	je     f0103c21 <vsnprintf+0x58>
f0103bf6:	85 d2                	test   %edx,%edx
f0103bf8:	7e 27                	jle    f0103c21 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103bfa:	ff 75 14             	pushl  0x14(%ebp)
f0103bfd:	ff 75 10             	pushl  0x10(%ebp)
f0103c00:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103c03:	50                   	push   %eax
f0103c04:	8d 83 b8 c3 fe ff    	lea    -0x13c48(%ebx),%eax
f0103c0a:	50                   	push   %eax
f0103c0b:	e8 ee fa ff ff       	call   f01036fe <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103c10:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103c13:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103c16:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103c19:	83 c4 10             	add    $0x10,%esp
}
f0103c1c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c1f:	c9                   	leave  
f0103c20:	c3                   	ret    
		return -E_INVAL;
f0103c21:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103c26:	eb f4                	jmp    f0103c1c <vsnprintf+0x53>

f0103c28 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103c28:	55                   	push   %ebp
f0103c29:	89 e5                	mov    %esp,%ebp
f0103c2b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103c2e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103c31:	50                   	push   %eax
f0103c32:	ff 75 10             	pushl  0x10(%ebp)
f0103c35:	ff 75 0c             	pushl  0xc(%ebp)
f0103c38:	ff 75 08             	pushl  0x8(%ebp)
f0103c3b:	e8 89 ff ff ff       	call   f0103bc9 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103c40:	c9                   	leave  
f0103c41:	c3                   	ret    

f0103c42 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103c42:	55                   	push   %ebp
f0103c43:	89 e5                	mov    %esp,%ebp
f0103c45:	57                   	push   %edi
f0103c46:	56                   	push   %esi
f0103c47:	53                   	push   %ebx
f0103c48:	83 ec 1c             	sub    $0x1c,%esp
f0103c4b:	e8 ff c4 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103c50:	81 c3 bc 36 01 00    	add    $0x136bc,%ebx
f0103c56:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103c59:	85 c0                	test   %eax,%eax
f0103c5b:	74 13                	je     f0103c70 <readline+0x2e>
		cprintf("%s", prompt);
f0103c5d:	83 ec 08             	sub    $0x8,%esp
f0103c60:	50                   	push   %eax
f0103c61:	8d 83 19 dd fe ff    	lea    -0x122e7(%ebx),%eax
f0103c67:	50                   	push   %eax
f0103c68:	e8 01 f6 ff ff       	call   f010326e <cprintf>
f0103c6d:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103c70:	83 ec 0c             	sub    $0xc,%esp
f0103c73:	6a 00                	push   $0x0
f0103c75:	e8 6d ca ff ff       	call   f01006e7 <iscons>
f0103c7a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103c7d:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103c80:	bf 00 00 00 00       	mov    $0x0,%edi
f0103c85:	eb 46                	jmp    f0103ccd <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103c87:	83 ec 08             	sub    $0x8,%esp
f0103c8a:	50                   	push   %eax
f0103c8b:	8d 83 cc e1 fe ff    	lea    -0x11e34(%ebx),%eax
f0103c91:	50                   	push   %eax
f0103c92:	e8 d7 f5 ff ff       	call   f010326e <cprintf>
			return NULL;
f0103c97:	83 c4 10             	add    $0x10,%esp
f0103c9a:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103c9f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ca2:	5b                   	pop    %ebx
f0103ca3:	5e                   	pop    %esi
f0103ca4:	5f                   	pop    %edi
f0103ca5:	5d                   	pop    %ebp
f0103ca6:	c3                   	ret    
			if (echoing)
f0103ca7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103cab:	75 05                	jne    f0103cb2 <readline+0x70>
			i--;
f0103cad:	83 ef 01             	sub    $0x1,%edi
f0103cb0:	eb 1b                	jmp    f0103ccd <readline+0x8b>
				cputchar('\b');
f0103cb2:	83 ec 0c             	sub    $0xc,%esp
f0103cb5:	6a 08                	push   $0x8
f0103cb7:	e8 0a ca ff ff       	call   f01006c6 <cputchar>
f0103cbc:	83 c4 10             	add    $0x10,%esp
f0103cbf:	eb ec                	jmp    f0103cad <readline+0x6b>
			buf[i++] = c;
f0103cc1:	89 f0                	mov    %esi,%eax
f0103cc3:	88 84 3b b4 1f 00 00 	mov    %al,0x1fb4(%ebx,%edi,1)
f0103cca:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103ccd:	e8 04 ca ff ff       	call   f01006d6 <getchar>
f0103cd2:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103cd4:	85 c0                	test   %eax,%eax
f0103cd6:	78 af                	js     f0103c87 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103cd8:	83 f8 08             	cmp    $0x8,%eax
f0103cdb:	0f 94 c2             	sete   %dl
f0103cde:	83 f8 7f             	cmp    $0x7f,%eax
f0103ce1:	0f 94 c0             	sete   %al
f0103ce4:	08 c2                	or     %al,%dl
f0103ce6:	74 04                	je     f0103cec <readline+0xaa>
f0103ce8:	85 ff                	test   %edi,%edi
f0103cea:	7f bb                	jg     f0103ca7 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103cec:	83 fe 1f             	cmp    $0x1f,%esi
f0103cef:	7e 1c                	jle    f0103d0d <readline+0xcb>
f0103cf1:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103cf7:	7f 14                	jg     f0103d0d <readline+0xcb>
			if (echoing)
f0103cf9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103cfd:	74 c2                	je     f0103cc1 <readline+0x7f>
				cputchar(c);
f0103cff:	83 ec 0c             	sub    $0xc,%esp
f0103d02:	56                   	push   %esi
f0103d03:	e8 be c9 ff ff       	call   f01006c6 <cputchar>
f0103d08:	83 c4 10             	add    $0x10,%esp
f0103d0b:	eb b4                	jmp    f0103cc1 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103d0d:	83 fe 0a             	cmp    $0xa,%esi
f0103d10:	74 05                	je     f0103d17 <readline+0xd5>
f0103d12:	83 fe 0d             	cmp    $0xd,%esi
f0103d15:	75 b6                	jne    f0103ccd <readline+0x8b>
			if (echoing)
f0103d17:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103d1b:	75 13                	jne    f0103d30 <readline+0xee>
			buf[i] = 0;
f0103d1d:	c6 84 3b b4 1f 00 00 	movb   $0x0,0x1fb4(%ebx,%edi,1)
f0103d24:	00 
			return buf;
f0103d25:	8d 83 b4 1f 00 00    	lea    0x1fb4(%ebx),%eax
f0103d2b:	e9 6f ff ff ff       	jmp    f0103c9f <readline+0x5d>
				cputchar('\n');
f0103d30:	83 ec 0c             	sub    $0xc,%esp
f0103d33:	6a 0a                	push   $0xa
f0103d35:	e8 8c c9 ff ff       	call   f01006c6 <cputchar>
f0103d3a:	83 c4 10             	add    $0x10,%esp
f0103d3d:	eb de                	jmp    f0103d1d <readline+0xdb>

f0103d3f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103d3f:	55                   	push   %ebp
f0103d40:	89 e5                	mov    %esp,%ebp
f0103d42:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103d45:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d4a:	eb 03                	jmp    f0103d4f <strlen+0x10>
		n++;
f0103d4c:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103d4f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103d53:	75 f7                	jne    f0103d4c <strlen+0xd>
	return n;
}
f0103d55:	5d                   	pop    %ebp
f0103d56:	c3                   	ret    

f0103d57 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103d57:	55                   	push   %ebp
f0103d58:	89 e5                	mov    %esp,%ebp
f0103d5a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d5d:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103d60:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d65:	eb 03                	jmp    f0103d6a <strnlen+0x13>
		n++;
f0103d67:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103d6a:	39 d0                	cmp    %edx,%eax
f0103d6c:	74 06                	je     f0103d74 <strnlen+0x1d>
f0103d6e:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103d72:	75 f3                	jne    f0103d67 <strnlen+0x10>
	return n;
}
f0103d74:	5d                   	pop    %ebp
f0103d75:	c3                   	ret    

f0103d76 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103d76:	55                   	push   %ebp
f0103d77:	89 e5                	mov    %esp,%ebp
f0103d79:	53                   	push   %ebx
f0103d7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d7d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103d80:	89 c2                	mov    %eax,%edx
f0103d82:	83 c1 01             	add    $0x1,%ecx
f0103d85:	83 c2 01             	add    $0x1,%edx
f0103d88:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103d8c:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103d8f:	84 db                	test   %bl,%bl
f0103d91:	75 ef                	jne    f0103d82 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103d93:	5b                   	pop    %ebx
f0103d94:	5d                   	pop    %ebp
f0103d95:	c3                   	ret    

f0103d96 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103d96:	55                   	push   %ebp
f0103d97:	89 e5                	mov    %esp,%ebp
f0103d99:	53                   	push   %ebx
f0103d9a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103d9d:	53                   	push   %ebx
f0103d9e:	e8 9c ff ff ff       	call   f0103d3f <strlen>
f0103da3:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103da6:	ff 75 0c             	pushl  0xc(%ebp)
f0103da9:	01 d8                	add    %ebx,%eax
f0103dab:	50                   	push   %eax
f0103dac:	e8 c5 ff ff ff       	call   f0103d76 <strcpy>
	return dst;
}
f0103db1:	89 d8                	mov    %ebx,%eax
f0103db3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103db6:	c9                   	leave  
f0103db7:	c3                   	ret    

f0103db8 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103db8:	55                   	push   %ebp
f0103db9:	89 e5                	mov    %esp,%ebp
f0103dbb:	56                   	push   %esi
f0103dbc:	53                   	push   %ebx
f0103dbd:	8b 75 08             	mov    0x8(%ebp),%esi
f0103dc0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103dc3:	89 f3                	mov    %esi,%ebx
f0103dc5:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103dc8:	89 f2                	mov    %esi,%edx
f0103dca:	eb 0f                	jmp    f0103ddb <strncpy+0x23>
		*dst++ = *src;
f0103dcc:	83 c2 01             	add    $0x1,%edx
f0103dcf:	0f b6 01             	movzbl (%ecx),%eax
f0103dd2:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103dd5:	80 39 01             	cmpb   $0x1,(%ecx)
f0103dd8:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0103ddb:	39 da                	cmp    %ebx,%edx
f0103ddd:	75 ed                	jne    f0103dcc <strncpy+0x14>
	}
	return ret;
}
f0103ddf:	89 f0                	mov    %esi,%eax
f0103de1:	5b                   	pop    %ebx
f0103de2:	5e                   	pop    %esi
f0103de3:	5d                   	pop    %ebp
f0103de4:	c3                   	ret    

f0103de5 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103de5:	55                   	push   %ebp
f0103de6:	89 e5                	mov    %esp,%ebp
f0103de8:	56                   	push   %esi
f0103de9:	53                   	push   %ebx
f0103dea:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ded:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103df0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103df3:	89 f0                	mov    %esi,%eax
f0103df5:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103df9:	85 c9                	test   %ecx,%ecx
f0103dfb:	75 0b                	jne    f0103e08 <strlcpy+0x23>
f0103dfd:	eb 17                	jmp    f0103e16 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103dff:	83 c2 01             	add    $0x1,%edx
f0103e02:	83 c0 01             	add    $0x1,%eax
f0103e05:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0103e08:	39 d8                	cmp    %ebx,%eax
f0103e0a:	74 07                	je     f0103e13 <strlcpy+0x2e>
f0103e0c:	0f b6 0a             	movzbl (%edx),%ecx
f0103e0f:	84 c9                	test   %cl,%cl
f0103e11:	75 ec                	jne    f0103dff <strlcpy+0x1a>
		*dst = '\0';
f0103e13:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103e16:	29 f0                	sub    %esi,%eax
}
f0103e18:	5b                   	pop    %ebx
f0103e19:	5e                   	pop    %esi
f0103e1a:	5d                   	pop    %ebp
f0103e1b:	c3                   	ret    

f0103e1c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103e1c:	55                   	push   %ebp
f0103e1d:	89 e5                	mov    %esp,%ebp
f0103e1f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103e22:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103e25:	eb 06                	jmp    f0103e2d <strcmp+0x11>
		p++, q++;
f0103e27:	83 c1 01             	add    $0x1,%ecx
f0103e2a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103e2d:	0f b6 01             	movzbl (%ecx),%eax
f0103e30:	84 c0                	test   %al,%al
f0103e32:	74 04                	je     f0103e38 <strcmp+0x1c>
f0103e34:	3a 02                	cmp    (%edx),%al
f0103e36:	74 ef                	je     f0103e27 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103e38:	0f b6 c0             	movzbl %al,%eax
f0103e3b:	0f b6 12             	movzbl (%edx),%edx
f0103e3e:	29 d0                	sub    %edx,%eax
}
f0103e40:	5d                   	pop    %ebp
f0103e41:	c3                   	ret    

f0103e42 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103e42:	55                   	push   %ebp
f0103e43:	89 e5                	mov    %esp,%ebp
f0103e45:	53                   	push   %ebx
f0103e46:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e49:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e4c:	89 c3                	mov    %eax,%ebx
f0103e4e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103e51:	eb 06                	jmp    f0103e59 <strncmp+0x17>
		n--, p++, q++;
f0103e53:	83 c0 01             	add    $0x1,%eax
f0103e56:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103e59:	39 d8                	cmp    %ebx,%eax
f0103e5b:	74 16                	je     f0103e73 <strncmp+0x31>
f0103e5d:	0f b6 08             	movzbl (%eax),%ecx
f0103e60:	84 c9                	test   %cl,%cl
f0103e62:	74 04                	je     f0103e68 <strncmp+0x26>
f0103e64:	3a 0a                	cmp    (%edx),%cl
f0103e66:	74 eb                	je     f0103e53 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103e68:	0f b6 00             	movzbl (%eax),%eax
f0103e6b:	0f b6 12             	movzbl (%edx),%edx
f0103e6e:	29 d0                	sub    %edx,%eax
}
f0103e70:	5b                   	pop    %ebx
f0103e71:	5d                   	pop    %ebp
f0103e72:	c3                   	ret    
		return 0;
f0103e73:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e78:	eb f6                	jmp    f0103e70 <strncmp+0x2e>

f0103e7a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103e7a:	55                   	push   %ebp
f0103e7b:	89 e5                	mov    %esp,%ebp
f0103e7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e80:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103e84:	0f b6 10             	movzbl (%eax),%edx
f0103e87:	84 d2                	test   %dl,%dl
f0103e89:	74 09                	je     f0103e94 <strchr+0x1a>
		if (*s == c)
f0103e8b:	38 ca                	cmp    %cl,%dl
f0103e8d:	74 0a                	je     f0103e99 <strchr+0x1f>
	for (; *s; s++)
f0103e8f:	83 c0 01             	add    $0x1,%eax
f0103e92:	eb f0                	jmp    f0103e84 <strchr+0xa>
			return (char *) s;
	return 0;
f0103e94:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e99:	5d                   	pop    %ebp
f0103e9a:	c3                   	ret    

f0103e9b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103e9b:	55                   	push   %ebp
f0103e9c:	89 e5                	mov    %esp,%ebp
f0103e9e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ea1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103ea5:	eb 03                	jmp    f0103eaa <strfind+0xf>
f0103ea7:	83 c0 01             	add    $0x1,%eax
f0103eaa:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103ead:	38 ca                	cmp    %cl,%dl
f0103eaf:	74 04                	je     f0103eb5 <strfind+0x1a>
f0103eb1:	84 d2                	test   %dl,%dl
f0103eb3:	75 f2                	jne    f0103ea7 <strfind+0xc>
			break;
	return (char *) s;
}
f0103eb5:	5d                   	pop    %ebp
f0103eb6:	c3                   	ret    

f0103eb7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103eb7:	55                   	push   %ebp
f0103eb8:	89 e5                	mov    %esp,%ebp
f0103eba:	57                   	push   %edi
f0103ebb:	56                   	push   %esi
f0103ebc:	53                   	push   %ebx
f0103ebd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103ec0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103ec3:	85 c9                	test   %ecx,%ecx
f0103ec5:	74 13                	je     f0103eda <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103ec7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103ecd:	75 05                	jne    f0103ed4 <memset+0x1d>
f0103ecf:	f6 c1 03             	test   $0x3,%cl
f0103ed2:	74 0d                	je     f0103ee1 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103ed4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ed7:	fc                   	cld    
f0103ed8:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103eda:	89 f8                	mov    %edi,%eax
f0103edc:	5b                   	pop    %ebx
f0103edd:	5e                   	pop    %esi
f0103ede:	5f                   	pop    %edi
f0103edf:	5d                   	pop    %ebp
f0103ee0:	c3                   	ret    
		c &= 0xFF;
f0103ee1:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103ee5:	89 d3                	mov    %edx,%ebx
f0103ee7:	c1 e3 08             	shl    $0x8,%ebx
f0103eea:	89 d0                	mov    %edx,%eax
f0103eec:	c1 e0 18             	shl    $0x18,%eax
f0103eef:	89 d6                	mov    %edx,%esi
f0103ef1:	c1 e6 10             	shl    $0x10,%esi
f0103ef4:	09 f0                	or     %esi,%eax
f0103ef6:	09 c2                	or     %eax,%edx
f0103ef8:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0103efa:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103efd:	89 d0                	mov    %edx,%eax
f0103eff:	fc                   	cld    
f0103f00:	f3 ab                	rep stos %eax,%es:(%edi)
f0103f02:	eb d6                	jmp    f0103eda <memset+0x23>

f0103f04 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103f04:	55                   	push   %ebp
f0103f05:	89 e5                	mov    %esp,%ebp
f0103f07:	57                   	push   %edi
f0103f08:	56                   	push   %esi
f0103f09:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f0c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103f0f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103f12:	39 c6                	cmp    %eax,%esi
f0103f14:	73 35                	jae    f0103f4b <memmove+0x47>
f0103f16:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103f19:	39 c2                	cmp    %eax,%edx
f0103f1b:	76 2e                	jbe    f0103f4b <memmove+0x47>
		s += n;
		d += n;
f0103f1d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f20:	89 d6                	mov    %edx,%esi
f0103f22:	09 fe                	or     %edi,%esi
f0103f24:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103f2a:	74 0c                	je     f0103f38 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103f2c:	83 ef 01             	sub    $0x1,%edi
f0103f2f:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103f32:	fd                   	std    
f0103f33:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103f35:	fc                   	cld    
f0103f36:	eb 21                	jmp    f0103f59 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f38:	f6 c1 03             	test   $0x3,%cl
f0103f3b:	75 ef                	jne    f0103f2c <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103f3d:	83 ef 04             	sub    $0x4,%edi
f0103f40:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103f43:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103f46:	fd                   	std    
f0103f47:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103f49:	eb ea                	jmp    f0103f35 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f4b:	89 f2                	mov    %esi,%edx
f0103f4d:	09 c2                	or     %eax,%edx
f0103f4f:	f6 c2 03             	test   $0x3,%dl
f0103f52:	74 09                	je     f0103f5d <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103f54:	89 c7                	mov    %eax,%edi
f0103f56:	fc                   	cld    
f0103f57:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103f59:	5e                   	pop    %esi
f0103f5a:	5f                   	pop    %edi
f0103f5b:	5d                   	pop    %ebp
f0103f5c:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f5d:	f6 c1 03             	test   $0x3,%cl
f0103f60:	75 f2                	jne    f0103f54 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103f62:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103f65:	89 c7                	mov    %eax,%edi
f0103f67:	fc                   	cld    
f0103f68:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103f6a:	eb ed                	jmp    f0103f59 <memmove+0x55>

f0103f6c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103f6c:	55                   	push   %ebp
f0103f6d:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103f6f:	ff 75 10             	pushl  0x10(%ebp)
f0103f72:	ff 75 0c             	pushl  0xc(%ebp)
f0103f75:	ff 75 08             	pushl  0x8(%ebp)
f0103f78:	e8 87 ff ff ff       	call   f0103f04 <memmove>
}
f0103f7d:	c9                   	leave  
f0103f7e:	c3                   	ret    

f0103f7f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103f7f:	55                   	push   %ebp
f0103f80:	89 e5                	mov    %esp,%ebp
f0103f82:	56                   	push   %esi
f0103f83:	53                   	push   %ebx
f0103f84:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f87:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103f8a:	89 c6                	mov    %eax,%esi
f0103f8c:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103f8f:	39 f0                	cmp    %esi,%eax
f0103f91:	74 1c                	je     f0103faf <memcmp+0x30>
		if (*s1 != *s2)
f0103f93:	0f b6 08             	movzbl (%eax),%ecx
f0103f96:	0f b6 1a             	movzbl (%edx),%ebx
f0103f99:	38 d9                	cmp    %bl,%cl
f0103f9b:	75 08                	jne    f0103fa5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103f9d:	83 c0 01             	add    $0x1,%eax
f0103fa0:	83 c2 01             	add    $0x1,%edx
f0103fa3:	eb ea                	jmp    f0103f8f <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0103fa5:	0f b6 c1             	movzbl %cl,%eax
f0103fa8:	0f b6 db             	movzbl %bl,%ebx
f0103fab:	29 d8                	sub    %ebx,%eax
f0103fad:	eb 05                	jmp    f0103fb4 <memcmp+0x35>
	}

	return 0;
f0103faf:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103fb4:	5b                   	pop    %ebx
f0103fb5:	5e                   	pop    %esi
f0103fb6:	5d                   	pop    %ebp
f0103fb7:	c3                   	ret    

f0103fb8 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103fb8:	55                   	push   %ebp
f0103fb9:	89 e5                	mov    %esp,%ebp
f0103fbb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fbe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103fc1:	89 c2                	mov    %eax,%edx
f0103fc3:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103fc6:	39 d0                	cmp    %edx,%eax
f0103fc8:	73 09                	jae    f0103fd3 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103fca:	38 08                	cmp    %cl,(%eax)
f0103fcc:	74 05                	je     f0103fd3 <memfind+0x1b>
	for (; s < ends; s++)
f0103fce:	83 c0 01             	add    $0x1,%eax
f0103fd1:	eb f3                	jmp    f0103fc6 <memfind+0xe>
			break;
	return (void *) s;
}
f0103fd3:	5d                   	pop    %ebp
f0103fd4:	c3                   	ret    

f0103fd5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103fd5:	55                   	push   %ebp
f0103fd6:	89 e5                	mov    %esp,%ebp
f0103fd8:	57                   	push   %edi
f0103fd9:	56                   	push   %esi
f0103fda:	53                   	push   %ebx
f0103fdb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103fde:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103fe1:	eb 03                	jmp    f0103fe6 <strtol+0x11>
		s++;
f0103fe3:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0103fe6:	0f b6 01             	movzbl (%ecx),%eax
f0103fe9:	3c 20                	cmp    $0x20,%al
f0103feb:	74 f6                	je     f0103fe3 <strtol+0xe>
f0103fed:	3c 09                	cmp    $0x9,%al
f0103fef:	74 f2                	je     f0103fe3 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103ff1:	3c 2b                	cmp    $0x2b,%al
f0103ff3:	74 2e                	je     f0104023 <strtol+0x4e>
	int neg = 0;
f0103ff5:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103ffa:	3c 2d                	cmp    $0x2d,%al
f0103ffc:	74 2f                	je     f010402d <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103ffe:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104004:	75 05                	jne    f010400b <strtol+0x36>
f0104006:	80 39 30             	cmpb   $0x30,(%ecx)
f0104009:	74 2c                	je     f0104037 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010400b:	85 db                	test   %ebx,%ebx
f010400d:	75 0a                	jne    f0104019 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010400f:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0104014:	80 39 30             	cmpb   $0x30,(%ecx)
f0104017:	74 28                	je     f0104041 <strtol+0x6c>
		base = 10;
f0104019:	b8 00 00 00 00       	mov    $0x0,%eax
f010401e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104021:	eb 50                	jmp    f0104073 <strtol+0x9e>
		s++;
f0104023:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0104026:	bf 00 00 00 00       	mov    $0x0,%edi
f010402b:	eb d1                	jmp    f0103ffe <strtol+0x29>
		s++, neg = 1;
f010402d:	83 c1 01             	add    $0x1,%ecx
f0104030:	bf 01 00 00 00       	mov    $0x1,%edi
f0104035:	eb c7                	jmp    f0103ffe <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104037:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010403b:	74 0e                	je     f010404b <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010403d:	85 db                	test   %ebx,%ebx
f010403f:	75 d8                	jne    f0104019 <strtol+0x44>
		s++, base = 8;
f0104041:	83 c1 01             	add    $0x1,%ecx
f0104044:	bb 08 00 00 00       	mov    $0x8,%ebx
f0104049:	eb ce                	jmp    f0104019 <strtol+0x44>
		s += 2, base = 16;
f010404b:	83 c1 02             	add    $0x2,%ecx
f010404e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104053:	eb c4                	jmp    f0104019 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0104055:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104058:	89 f3                	mov    %esi,%ebx
f010405a:	80 fb 19             	cmp    $0x19,%bl
f010405d:	77 29                	ja     f0104088 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010405f:	0f be d2             	movsbl %dl,%edx
f0104062:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104065:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104068:	7d 30                	jge    f010409a <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f010406a:	83 c1 01             	add    $0x1,%ecx
f010406d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104071:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0104073:	0f b6 11             	movzbl (%ecx),%edx
f0104076:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104079:	89 f3                	mov    %esi,%ebx
f010407b:	80 fb 09             	cmp    $0x9,%bl
f010407e:	77 d5                	ja     f0104055 <strtol+0x80>
			dig = *s - '0';
f0104080:	0f be d2             	movsbl %dl,%edx
f0104083:	83 ea 30             	sub    $0x30,%edx
f0104086:	eb dd                	jmp    f0104065 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0104088:	8d 72 bf             	lea    -0x41(%edx),%esi
f010408b:	89 f3                	mov    %esi,%ebx
f010408d:	80 fb 19             	cmp    $0x19,%bl
f0104090:	77 08                	ja     f010409a <strtol+0xc5>
			dig = *s - 'A' + 10;
f0104092:	0f be d2             	movsbl %dl,%edx
f0104095:	83 ea 37             	sub    $0x37,%edx
f0104098:	eb cb                	jmp    f0104065 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f010409a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010409e:	74 05                	je     f01040a5 <strtol+0xd0>
		*endptr = (char *) s;
f01040a0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01040a3:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01040a5:	89 c2                	mov    %eax,%edx
f01040a7:	f7 da                	neg    %edx
f01040a9:	85 ff                	test   %edi,%edi
f01040ab:	0f 45 c2             	cmovne %edx,%eax
}
f01040ae:	5b                   	pop    %ebx
f01040af:	5e                   	pop    %esi
f01040b0:	5f                   	pop    %edi
f01040b1:	5d                   	pop    %ebp
f01040b2:	c3                   	ret    
f01040b3:	66 90                	xchg   %ax,%ax
f01040b5:	66 90                	xchg   %ax,%ax
f01040b7:	66 90                	xchg   %ax,%ax
f01040b9:	66 90                	xchg   %ax,%ax
f01040bb:	66 90                	xchg   %ax,%ax
f01040bd:	66 90                	xchg   %ax,%ax
f01040bf:	90                   	nop

f01040c0 <__udivdi3>:
f01040c0:	55                   	push   %ebp
f01040c1:	57                   	push   %edi
f01040c2:	56                   	push   %esi
f01040c3:	53                   	push   %ebx
f01040c4:	83 ec 1c             	sub    $0x1c,%esp
f01040c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01040cb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01040cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01040d3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01040d7:	85 d2                	test   %edx,%edx
f01040d9:	75 35                	jne    f0104110 <__udivdi3+0x50>
f01040db:	39 f3                	cmp    %esi,%ebx
f01040dd:	0f 87 bd 00 00 00    	ja     f01041a0 <__udivdi3+0xe0>
f01040e3:	85 db                	test   %ebx,%ebx
f01040e5:	89 d9                	mov    %ebx,%ecx
f01040e7:	75 0b                	jne    f01040f4 <__udivdi3+0x34>
f01040e9:	b8 01 00 00 00       	mov    $0x1,%eax
f01040ee:	31 d2                	xor    %edx,%edx
f01040f0:	f7 f3                	div    %ebx
f01040f2:	89 c1                	mov    %eax,%ecx
f01040f4:	31 d2                	xor    %edx,%edx
f01040f6:	89 f0                	mov    %esi,%eax
f01040f8:	f7 f1                	div    %ecx
f01040fa:	89 c6                	mov    %eax,%esi
f01040fc:	89 e8                	mov    %ebp,%eax
f01040fe:	89 f7                	mov    %esi,%edi
f0104100:	f7 f1                	div    %ecx
f0104102:	89 fa                	mov    %edi,%edx
f0104104:	83 c4 1c             	add    $0x1c,%esp
f0104107:	5b                   	pop    %ebx
f0104108:	5e                   	pop    %esi
f0104109:	5f                   	pop    %edi
f010410a:	5d                   	pop    %ebp
f010410b:	c3                   	ret    
f010410c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104110:	39 f2                	cmp    %esi,%edx
f0104112:	77 7c                	ja     f0104190 <__udivdi3+0xd0>
f0104114:	0f bd fa             	bsr    %edx,%edi
f0104117:	83 f7 1f             	xor    $0x1f,%edi
f010411a:	0f 84 98 00 00 00    	je     f01041b8 <__udivdi3+0xf8>
f0104120:	89 f9                	mov    %edi,%ecx
f0104122:	b8 20 00 00 00       	mov    $0x20,%eax
f0104127:	29 f8                	sub    %edi,%eax
f0104129:	d3 e2                	shl    %cl,%edx
f010412b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010412f:	89 c1                	mov    %eax,%ecx
f0104131:	89 da                	mov    %ebx,%edx
f0104133:	d3 ea                	shr    %cl,%edx
f0104135:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0104139:	09 d1                	or     %edx,%ecx
f010413b:	89 f2                	mov    %esi,%edx
f010413d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104141:	89 f9                	mov    %edi,%ecx
f0104143:	d3 e3                	shl    %cl,%ebx
f0104145:	89 c1                	mov    %eax,%ecx
f0104147:	d3 ea                	shr    %cl,%edx
f0104149:	89 f9                	mov    %edi,%ecx
f010414b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010414f:	d3 e6                	shl    %cl,%esi
f0104151:	89 eb                	mov    %ebp,%ebx
f0104153:	89 c1                	mov    %eax,%ecx
f0104155:	d3 eb                	shr    %cl,%ebx
f0104157:	09 de                	or     %ebx,%esi
f0104159:	89 f0                	mov    %esi,%eax
f010415b:	f7 74 24 08          	divl   0x8(%esp)
f010415f:	89 d6                	mov    %edx,%esi
f0104161:	89 c3                	mov    %eax,%ebx
f0104163:	f7 64 24 0c          	mull   0xc(%esp)
f0104167:	39 d6                	cmp    %edx,%esi
f0104169:	72 0c                	jb     f0104177 <__udivdi3+0xb7>
f010416b:	89 f9                	mov    %edi,%ecx
f010416d:	d3 e5                	shl    %cl,%ebp
f010416f:	39 c5                	cmp    %eax,%ebp
f0104171:	73 5d                	jae    f01041d0 <__udivdi3+0x110>
f0104173:	39 d6                	cmp    %edx,%esi
f0104175:	75 59                	jne    f01041d0 <__udivdi3+0x110>
f0104177:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010417a:	31 ff                	xor    %edi,%edi
f010417c:	89 fa                	mov    %edi,%edx
f010417e:	83 c4 1c             	add    $0x1c,%esp
f0104181:	5b                   	pop    %ebx
f0104182:	5e                   	pop    %esi
f0104183:	5f                   	pop    %edi
f0104184:	5d                   	pop    %ebp
f0104185:	c3                   	ret    
f0104186:	8d 76 00             	lea    0x0(%esi),%esi
f0104189:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104190:	31 ff                	xor    %edi,%edi
f0104192:	31 c0                	xor    %eax,%eax
f0104194:	89 fa                	mov    %edi,%edx
f0104196:	83 c4 1c             	add    $0x1c,%esp
f0104199:	5b                   	pop    %ebx
f010419a:	5e                   	pop    %esi
f010419b:	5f                   	pop    %edi
f010419c:	5d                   	pop    %ebp
f010419d:	c3                   	ret    
f010419e:	66 90                	xchg   %ax,%ax
f01041a0:	31 ff                	xor    %edi,%edi
f01041a2:	89 e8                	mov    %ebp,%eax
f01041a4:	89 f2                	mov    %esi,%edx
f01041a6:	f7 f3                	div    %ebx
f01041a8:	89 fa                	mov    %edi,%edx
f01041aa:	83 c4 1c             	add    $0x1c,%esp
f01041ad:	5b                   	pop    %ebx
f01041ae:	5e                   	pop    %esi
f01041af:	5f                   	pop    %edi
f01041b0:	5d                   	pop    %ebp
f01041b1:	c3                   	ret    
f01041b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01041b8:	39 f2                	cmp    %esi,%edx
f01041ba:	72 06                	jb     f01041c2 <__udivdi3+0x102>
f01041bc:	31 c0                	xor    %eax,%eax
f01041be:	39 eb                	cmp    %ebp,%ebx
f01041c0:	77 d2                	ja     f0104194 <__udivdi3+0xd4>
f01041c2:	b8 01 00 00 00       	mov    $0x1,%eax
f01041c7:	eb cb                	jmp    f0104194 <__udivdi3+0xd4>
f01041c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01041d0:	89 d8                	mov    %ebx,%eax
f01041d2:	31 ff                	xor    %edi,%edi
f01041d4:	eb be                	jmp    f0104194 <__udivdi3+0xd4>
f01041d6:	66 90                	xchg   %ax,%ax
f01041d8:	66 90                	xchg   %ax,%ax
f01041da:	66 90                	xchg   %ax,%ax
f01041dc:	66 90                	xchg   %ax,%ax
f01041de:	66 90                	xchg   %ax,%ax

f01041e0 <__umoddi3>:
f01041e0:	55                   	push   %ebp
f01041e1:	57                   	push   %edi
f01041e2:	56                   	push   %esi
f01041e3:	53                   	push   %ebx
f01041e4:	83 ec 1c             	sub    $0x1c,%esp
f01041e7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01041eb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01041ef:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01041f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01041f7:	85 ed                	test   %ebp,%ebp
f01041f9:	89 f0                	mov    %esi,%eax
f01041fb:	89 da                	mov    %ebx,%edx
f01041fd:	75 19                	jne    f0104218 <__umoddi3+0x38>
f01041ff:	39 df                	cmp    %ebx,%edi
f0104201:	0f 86 b1 00 00 00    	jbe    f01042b8 <__umoddi3+0xd8>
f0104207:	f7 f7                	div    %edi
f0104209:	89 d0                	mov    %edx,%eax
f010420b:	31 d2                	xor    %edx,%edx
f010420d:	83 c4 1c             	add    $0x1c,%esp
f0104210:	5b                   	pop    %ebx
f0104211:	5e                   	pop    %esi
f0104212:	5f                   	pop    %edi
f0104213:	5d                   	pop    %ebp
f0104214:	c3                   	ret    
f0104215:	8d 76 00             	lea    0x0(%esi),%esi
f0104218:	39 dd                	cmp    %ebx,%ebp
f010421a:	77 f1                	ja     f010420d <__umoddi3+0x2d>
f010421c:	0f bd cd             	bsr    %ebp,%ecx
f010421f:	83 f1 1f             	xor    $0x1f,%ecx
f0104222:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104226:	0f 84 b4 00 00 00    	je     f01042e0 <__umoddi3+0x100>
f010422c:	b8 20 00 00 00       	mov    $0x20,%eax
f0104231:	89 c2                	mov    %eax,%edx
f0104233:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104237:	29 c2                	sub    %eax,%edx
f0104239:	89 c1                	mov    %eax,%ecx
f010423b:	89 f8                	mov    %edi,%eax
f010423d:	d3 e5                	shl    %cl,%ebp
f010423f:	89 d1                	mov    %edx,%ecx
f0104241:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104245:	d3 e8                	shr    %cl,%eax
f0104247:	09 c5                	or     %eax,%ebp
f0104249:	8b 44 24 04          	mov    0x4(%esp),%eax
f010424d:	89 c1                	mov    %eax,%ecx
f010424f:	d3 e7                	shl    %cl,%edi
f0104251:	89 d1                	mov    %edx,%ecx
f0104253:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104257:	89 df                	mov    %ebx,%edi
f0104259:	d3 ef                	shr    %cl,%edi
f010425b:	89 c1                	mov    %eax,%ecx
f010425d:	89 f0                	mov    %esi,%eax
f010425f:	d3 e3                	shl    %cl,%ebx
f0104261:	89 d1                	mov    %edx,%ecx
f0104263:	89 fa                	mov    %edi,%edx
f0104265:	d3 e8                	shr    %cl,%eax
f0104267:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010426c:	09 d8                	or     %ebx,%eax
f010426e:	f7 f5                	div    %ebp
f0104270:	d3 e6                	shl    %cl,%esi
f0104272:	89 d1                	mov    %edx,%ecx
f0104274:	f7 64 24 08          	mull   0x8(%esp)
f0104278:	39 d1                	cmp    %edx,%ecx
f010427a:	89 c3                	mov    %eax,%ebx
f010427c:	89 d7                	mov    %edx,%edi
f010427e:	72 06                	jb     f0104286 <__umoddi3+0xa6>
f0104280:	75 0e                	jne    f0104290 <__umoddi3+0xb0>
f0104282:	39 c6                	cmp    %eax,%esi
f0104284:	73 0a                	jae    f0104290 <__umoddi3+0xb0>
f0104286:	2b 44 24 08          	sub    0x8(%esp),%eax
f010428a:	19 ea                	sbb    %ebp,%edx
f010428c:	89 d7                	mov    %edx,%edi
f010428e:	89 c3                	mov    %eax,%ebx
f0104290:	89 ca                	mov    %ecx,%edx
f0104292:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0104297:	29 de                	sub    %ebx,%esi
f0104299:	19 fa                	sbb    %edi,%edx
f010429b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010429f:	89 d0                	mov    %edx,%eax
f01042a1:	d3 e0                	shl    %cl,%eax
f01042a3:	89 d9                	mov    %ebx,%ecx
f01042a5:	d3 ee                	shr    %cl,%esi
f01042a7:	d3 ea                	shr    %cl,%edx
f01042a9:	09 f0                	or     %esi,%eax
f01042ab:	83 c4 1c             	add    $0x1c,%esp
f01042ae:	5b                   	pop    %ebx
f01042af:	5e                   	pop    %esi
f01042b0:	5f                   	pop    %edi
f01042b1:	5d                   	pop    %ebp
f01042b2:	c3                   	ret    
f01042b3:	90                   	nop
f01042b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01042b8:	85 ff                	test   %edi,%edi
f01042ba:	89 f9                	mov    %edi,%ecx
f01042bc:	75 0b                	jne    f01042c9 <__umoddi3+0xe9>
f01042be:	b8 01 00 00 00       	mov    $0x1,%eax
f01042c3:	31 d2                	xor    %edx,%edx
f01042c5:	f7 f7                	div    %edi
f01042c7:	89 c1                	mov    %eax,%ecx
f01042c9:	89 d8                	mov    %ebx,%eax
f01042cb:	31 d2                	xor    %edx,%edx
f01042cd:	f7 f1                	div    %ecx
f01042cf:	89 f0                	mov    %esi,%eax
f01042d1:	f7 f1                	div    %ecx
f01042d3:	e9 31 ff ff ff       	jmp    f0104209 <__umoddi3+0x29>
f01042d8:	90                   	nop
f01042d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01042e0:	39 dd                	cmp    %ebx,%ebp
f01042e2:	72 08                	jb     f01042ec <__umoddi3+0x10c>
f01042e4:	39 f7                	cmp    %esi,%edi
f01042e6:	0f 87 21 ff ff ff    	ja     f010420d <__umoddi3+0x2d>
f01042ec:	89 da                	mov    %ebx,%edx
f01042ee:	89 f0                	mov    %esi,%eax
f01042f0:	29 f8                	sub    %edi,%eax
f01042f2:	19 ea                	sbb    %ebp,%edx
f01042f4:	e9 14 ff ff ff       	jmp    f010420d <__umoddi3+0x2d>
