/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * kron.h
 *
 * Code generation for function 'kron'
 *
 */

#ifndef KRON_H
#define KRON_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern void b_kron(const emxArray_real_T *A, const double B[9], emxArray_real_T *
                   K);
extern void c_kron(const emxArray_real_T *A, const double B[6], emxArray_real_T *
                   K);
extern void kron(const emxArray_real_T *A, const emxArray_real_T *B,
                 emxArray_real_T *K);

#endif

/* End of code generation (kron.h) */
