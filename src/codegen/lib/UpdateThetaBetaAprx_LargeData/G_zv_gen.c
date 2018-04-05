/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * G_zv_gen.c
 *
 * Code generation for function 'G_zv_gen'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "G_zv_gen.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"

/* Function Definitions */
void G_zv_gen(const emxArray_real_T *zv, double m, double q, emxArray_real_T
              *G_zv)
{
  emxArray_real_T *y;
  int i4;
  int loop_ub;
  emxArray_real_T *x;
  emxArray_real_T *b_y;
  emxArray_int32_T *r7;

  /*  G_zv_gen - Function to generate G_z matrix given vector z(v) */
  /*  */
  /*  Syntax: */
  /*  G_zv = G_zv_gen(zv, m, q) */
  /*  */
  /*  Inputs: */
  /*     zv   - NT x V, orignial imaging data matrix */
  /*     m    - Number of Gaussian components in MoG */
  /*     q    - Number of Independent Components (IC) */
  /*  */
  /*  Outputs: */
  /*     G_zv   - G_z matrix of possible IC membership permutations */
  /*  */
  /*  See also: UpdateThetaBetaAprx_Vect.m, UpdateThetaBeta.m  */
  emxInit_real_T1(&y, 2);
  if (q < 1.0) {
    i4 = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = 0;
    emxEnsureCapacity((emxArray__common *)y, i4, sizeof(double));
  } else if (rtIsInf(q) && (1.0 == q)) {
    i4 = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = 1;
    emxEnsureCapacity((emxArray__common *)y, i4, sizeof(double));
    y->data[0] = rtNaN;
  } else {
    i4 = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = (int)floor(q - 1.0) + 1;
    emxEnsureCapacity((emxArray__common *)y, i4, sizeof(double));
    loop_ub = (int)floor(q - 1.0);
    for (i4 = 0; i4 <= loop_ub; i4++) {
      y->data[y->size[0] * i4] = 1.0 + (double)i4;
    }
  }

  emxInit_real_T2(&x, 1);
  i4 = x->size[0];
  x->size[0] = y->size[1];
  emxEnsureCapacity((emxArray__common *)x, i4, sizeof(double));
  loop_ub = y->size[1];
  for (i4 = 0; i4 < loop_ub; i4++) {
    x->data[i4] = y->data[y->size[0] * i4];
  }

  emxFree_real_T(&y);
  emxInit_real_T2(&b_y, 1);
  i4 = b_y->size[0];
  b_y->size[0] = x->size[0];
  emxEnsureCapacity((emxArray__common *)b_y, i4, sizeof(double));
  loop_ub = x->size[0];
  for (i4 = 0; i4 < loop_ub; i4++) {
    b_y->data[i4] = (x->data[i4] - 1.0) * m + zv->data[i4];
  }

  i4 = G_zv->size[0] * G_zv->size[1];
  G_zv->size[0] = (int)q;
  G_zv->size[1] = (int)(m * q);
  emxEnsureCapacity((emxArray__common *)G_zv, i4, sizeof(double));
  loop_ub = (int)q * (int)(m * q);
  for (i4 = 0; i4 < loop_ub; i4++) {
    G_zv->data[i4] = 0.0;
  }

  emxInit_int32_T(&r7, 1);
  i4 = r7->size[0];
  r7->size[0] = x->size[0];
  emxEnsureCapacity((emxArray__common *)r7, i4, sizeof(int));
  loop_ub = x->size[0];
  for (i4 = 0; i4 < loop_ub; i4++) {
    r7->data[i4] = (int)x->data[i4] + (int)q * ((int)b_y->data[i4] - 1);
  }

  emxFree_real_T(&b_y);
  emxFree_real_T(&x);
  loop_ub = r7->size[0];
  for (i4 = 0; i4 < loop_ub; i4++) {
    G_zv->data[r7->data[i4] - 1] = 1.0;
  }

  emxFree_int32_T(&r7);
}

/* End of code generation (G_zv_gen.c) */
