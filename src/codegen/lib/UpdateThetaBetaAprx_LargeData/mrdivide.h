/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * mrdivide.h
 *
 * Code generation for function 'mrdivide'
 *
 */

#ifndef MRDIVIDE_H
#define MRDIVIDE_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern void b_mrdivide(const emxArray_real_T *A, const emxArray_real32_T *B,
  emxArray_real32_T *y);
extern void mrdivide(const emxArray_real_T *A, const double B[4],
                     emxArray_real_T *y);

#endif

/* End of code generation (mrdivide.h) */
