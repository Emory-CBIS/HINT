/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * rdivide.c
 *
 * Code generation for function 'rdivide'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "rdivide.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"

/* Function Definitions */
void rdivide(const emxArray_real_T *y, emxArray_real_T *z)
{
  int i9;
  int loop_ub;
  i9 = z->size[0];
  z->size[0] = y->size[0];
  emxEnsureCapacity((emxArray__common *)z, i9, sizeof(double));
  loop_ub = y->size[0];
  for (i9 = 0; i9 < loop_ub; i9++) {
    z->data[i9] = 1.0 / y->data[i9];
  }
}

/* End of code generation (rdivide.c) */
