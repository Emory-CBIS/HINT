/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * log.h
 *
 * Code generation for function 'log'
 *
 */

#ifndef LOG_H
#define LOG_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern void b_log(emxArray_real_T *x);
extern void c_log(float x[60]);

#endif

/* End of code generation (log.h) */
