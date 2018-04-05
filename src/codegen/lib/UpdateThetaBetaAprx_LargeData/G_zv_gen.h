/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * G_zv_gen.h
 *
 * Code generation for function 'G_zv_gen'
 *
 */

#ifndef G_ZV_GEN_H
#define G_ZV_GEN_H

/* Include files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "UpdateThetaBetaAprx_LargeData_types.h"

/* Function Declarations */
extern void G_zv_gen(const emxArray_real_T *zv, double m, double q,
                     emxArray_real_T *G_zv);

#endif

/* End of code generation (G_zv_gen.h) */
