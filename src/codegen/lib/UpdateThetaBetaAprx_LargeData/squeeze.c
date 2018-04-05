/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * squeeze.c
 *
 * Code generation for function 'squeeze'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "squeeze.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"

/* Function Definitions */
void squeeze(const emxArray_real_T *a, emxArray_real_T *b)
{
  int k;
  int i10;
  int sqsz[3];
  k = 3;
  while ((k > 2) && (a->size[2] == 1)) {
    k = 2;
  }

  if (k <= 2) {
    sqsz[0] = a->size[0];
    i10 = b->size[0] * b->size[1];
    b->size[0] = sqsz[0];
    b->size[1] = 1;
    emxEnsureCapacity((emxArray__common *)b, i10, sizeof(double));
    i10 = a->size[0] * a->size[2];
    for (k = 0; k + 1 <= i10; k++) {
      b->data[k] = a->data[k];
    }
  } else {
    for (i10 = 0; i10 < 3; i10++) {
      sqsz[i10] = 1;
    }

    k = 0;
    if (a->size[0] != 1) {
      sqsz[0] = a->size[0];
      k = 1;
    }

    if (a->size[2] != 1) {
      sqsz[k] = a->size[2];
    }

    i10 = b->size[0] * b->size[1];
    b->size[0] = sqsz[0];
    b->size[1] = sqsz[1];
    emxEnsureCapacity((emxArray__common *)b, i10, sizeof(double));
    i10 = a->size[0] * a->size[2];
    for (k = 0; k + 1 <= i10; k++) {
      b->data[k] = a->data[k];
    }
  }
}

/* End of code generation (squeeze.c) */
