/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * sum.c
 *
 * Code generation for function 'sum'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "sum.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"

/* Function Definitions */
float b_sum(const float x[60])
{
  float y;
  int k;
  y = x[0];
  for (k = 0; k < 59; k++) {
    y += x[k + 1];
  }

  return y;
}

void c_sum(const emxArray_real_T *x, emxArray_real_T *y)
{
  int k;
  unsigned int sz[3];
  int vstride;
  int j;
  int i11;
  double s;
  for (k = 0; k < 3; k++) {
    sz[k] = (unsigned int)x->size[k];
  }

  k = y->size[0] * y->size[1];
  y->size[0] = (int)sz[0];
  y->size[1] = (int)sz[1];
  emxEnsureCapacity((emxArray__common *)y, k, sizeof(double));
  if ((x->size[0] == 0) || (x->size[1] == 0) || (x->size[2] == 0)) {
    k = y->size[0] * y->size[1];
    emxEnsureCapacity((emxArray__common *)y, k, sizeof(double));
    vstride = y->size[1];
    for (k = 0; k < vstride; k++) {
      j = y->size[0];
      for (i11 = 0; i11 < j; i11++) {
        y->data[i11 + y->size[0] * k] = 0.0;
      }
    }
  } else {
    k = 3;
    while ((k > 2) && (x->size[2] == 1)) {
      k = 2;
    }

    if (3 > k) {
      vstride = x->size[0] * x->size[1] * x->size[2];
    } else {
      vstride = 1;
      for (k = 0; k < 2; k++) {
        vstride *= x->size[k];
      }
    }

    for (j = 0; j + 1 <= vstride; j++) {
      s = x->data[j];
      for (k = 2; k <= x->size[2]; k++) {
        s += x->data[j + (k - 1) * vstride];
      }

      y->data[j] = s;
    }
  }
}

double sum(const emxArray_real_T *x)
{
  double y;
  int k;
  if (x->size[0] == 0) {
    y = 0.0;
  } else {
    y = x->data[0];
    for (k = 2; k <= x->size[0]; k++) {
      y += x->data[k - 1];
    }
  }

  return y;
}

/* End of code generation (sum.c) */
