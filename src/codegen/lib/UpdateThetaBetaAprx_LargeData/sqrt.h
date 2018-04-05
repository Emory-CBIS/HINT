/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * sqrt.h
 *
 * Code generation for function 'sqrt'
 *
 */

#ifndef SQRT_H
#define SQRT_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern void b_sqrt(float x[60]);
extern void c_sqrt(creal_T *x);

#endif

/* End of code generation (sqrt.h) */
