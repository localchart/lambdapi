/*	  Copyright (c) 20011, Simon Stapleton (simon.stapleton@gmail.com)	  */
/*										  */
/*				All rights reserved.				  */
/*										  */
/* Redistribution  and	use   in  source  and  binary  forms,	with  or  without */
/* modification, are permitted provided that the following conditions are met:	  */
/*										  */
/* Redistributions of  source code must	 retain the above copyright  notice, this */
/* list of conditions and the following disclaimer.				  */
/*										  */
/* Redistributions in binary form must reproduce the above copyright notice, this */
/* list of conditions and the following disclaimer in the documentation and/or	  */
/* other materials provided with the distribution.				  */
/*										  */
/* Neither the name of	the developer nor the names of	other contributors may be */
/* used	 to  endorse or	 promote  products  derived  from this	software  without */
/* specific prior written permission.						  */
/*										  */
/* THIS SOFTWARE  IS PROVIDED BY THE  COPYRIGHT HOLDERS AND CONTRIBUTORS  "AS IS" */
/* AND ANY  EXPRESS OR	IMPLIED WARRANTIES,  INCLUDING, BUT  NOT LIMITED  TO, THE */
/* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE */
/* DISCLAIMED. IN NO  EVENT SHALL THE COPYRIGHT HOLDER OR  CONTRIBUTORS BE LIABLE */
/* FOR	ANY DIRECT,  INDIRECT, INCIDENTAL,  SPECIAL, EXEMPLARY,	 OR CONSEQUENTIAL */
/* DAMAGES (INCLUDING,	BUT NOT	 LIMITED TO, PROCUREMENT  OF SUBSTITUTE	 GOODS OR */
/* SERVICES; LOSS  OF USE,  DATA, OR PROFITS;  OR BUSINESS  INTERRUPTION) HOWEVER */
/* CAUSED AND ON ANY THEORY OF	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, */
/* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING	IN ANY WAY OUT OF THE USE */
/* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.		  */

.include "sysequates.inc"

/* Privileged mode context switcher */
FUNC	switch_context_priv
	srsdb	sp!, #SYS_MODE	/* save LR_<mode> and SPSR_<mode> to system mode stack */

	cps	#SYS_MODE	/* Go to system mode */
	push	{r0-r12}	/* Save registers */

	and	r0, sp, #4	/* align the stack and save adjustment with LR_user */
	sub	sp, sp, r0
	push	{r0, lr}

.global switch_context_do
switch_context_do:
	/* Do we need to switch context? */
	ldr	r0, =__current_task
	ldr	r1, [r0]
	ldr	r0, =__next_task
	ldr	r2, [r0]
	
	cmp	r1, #0			/* first time around, this will be zero */
	beq	.Lswitch		/* bail to actual task switch */	
	
	cmp	r1, r2			/* otherwise, compare current task to next */

	/* At this point we have everything we need on the sysmode (user) stack	*/
	/* {stack adjust, lr}_user, {r0-r12}_user, {SPSR, LR}_irq 		*/
	/* Save our stack pointer, and swap in the new one before returning	*/

	ldrne	r0, =__current_task	/* save current stack pointer */
	ldrne	r0, [r0]
	strne	sp, [r0, #4]		/* stack pointer is second word of task object */
	
.Lswitch:
	ldrne	r0,  =__next_task	/* swap out the task */
	ldrne	r2,  [r0]
	ldrne	r0,  =__current_task
	strne	r2,  [r0]
	ldrne	sp,  [r2, #4]		/* and restore stack pointer */
	
.Lirq_exit:
	pop	{r0, lr}		/* restore LR_user and readjust stack */
	add	sp, sp, r0
	
	pop	{r0-r12}		/* and other registers */
	rfeia	sp!			/* before returning */
	
.extern	__next_task
.extern	__current_task
