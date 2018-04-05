/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * sqrtm.c
 *
 * Code generation for function 'sqrtm'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "sqrtm.h"
#include "sqrt.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"
#include "norm.h"
#include "schur.h"
#include "UpdateThetaBetaAprx_LargeData_rtwutil.h"

/* Function Declarations */
static boolean_T isUTmatD(const emxArray_creal_T *T);

/* Function Definitions */
static boolean_T isUTmatD(const emxArray_creal_T *T)
{
  boolean_T p;
  int j;
  int exitg2;
  int i;
  int exitg1;
  boolean_T b_T;
  j = 0;
  do {
    exitg2 = 0;
    if (j + 1 <= T->size[1]) {
      i = 1;
      do {
        exitg1 = 0;
        if (i <= j) {
          b_T = ((T->data[(i + T->size[0] * j) - 1].re != 0.0) || (T->data[(i +
                   T->size[0] * j) - 1].im != 0.0));
          if (b_T) {
            p = false;
            exitg1 = 1;
          } else {
            i++;
          }
        } else {
          j++;
          exitg1 = 2;
        }
      } while (exitg1 == 0);

      if (exitg1 == 1) {
        exitg2 = 1;
      }
    } else {
      p = true;
      exitg2 = 1;
    }
  } while (exitg2 == 0);

  return p;
}

void sqrtm(const emxArray_real_T *A, emxArray_creal_T *X)
{
  emxArray_creal_T *Q;
  emxArray_creal_T *T;
  int n;
  int i14;
  emxArray_creal_T *R;
  unsigned int uv0[2];
  int br;
  int j;
  emxArray_creal_T *y;
  int i;
  int k;
  double s_re;
  double s_im;
  double T_re;
  double R_re;
  int m;
  int ar;
  double R_im;
  int i15;
  emxArray_creal_T *b;
  double bim;
  int ic;
  int ib;
  boolean_T b_R;
  int ia;
  emxArray_real_T *b_X;
  boolean_T exitg1;
  emxInit_creal_T(&Q, 2);
  emxInit_creal_T(&T, 2);
  schur(A, Q, T);
  n = A->size[0];
  for (i14 = 0; i14 < 2; i14++) {
    uv0[i14] = (unsigned int)T->size[i14];
  }

  emxInit_creal_T(&R, 2);
  i14 = R->size[0] * R->size[1];
  R->size[0] = (int)uv0[0];
  R->size[1] = (int)uv0[1];
  emxEnsureCapacity((emxArray__common *)R, i14, sizeof(creal_T));
  br = (int)uv0[0] * (int)uv0[1];
  for (i14 = 0; i14 < br; i14++) {
    R->data[i14].re = 0.0;
    R->data[i14].im = 0.0;
  }

  if (isUTmatD(T)) {
    for (j = 0; j + 1 <= n; j++) {
      R->data[j + R->size[0] * j] = T->data[j + T->size[0] * j];
      c_sqrt(&R->data[j + R->size[0] * j]);
    }
  } else {
    for (j = 0; j + 1 <= n; j++) {
      R->data[j + R->size[0] * j] = T->data[j + T->size[0] * j];
      c_sqrt(&R->data[j + R->size[0] * j]);
      for (i = j - 1; i + 1 > 0; i--) {
        s_re = 0.0;
        s_im = 0.0;
        for (k = i + 1; k + 1 <= j; k++) {
          R_re = R->data[i + R->size[0] * k].re * R->data[k + R->size[0] * j].re
            - R->data[i + R->size[0] * k].im * R->data[k + R->size[0] * j].im;
          R_im = R->data[i + R->size[0] * k].re * R->data[k + R->size[0] * j].im
            + R->data[i + R->size[0] * k].im * R->data[k + R->size[0] * j].re;
          s_re += R_re;
          s_im += R_im;
        }

        T_re = T->data[i + T->size[0] * j].re - s_re;
        s_im = T->data[i + T->size[0] * j].im - s_im;
        R_re = R->data[i + R->size[0] * i].re + R->data[j + R->size[0] * j].re;
        R_im = R->data[i + R->size[0] * i].im + R->data[j + R->size[0] * j].im;
        if (R_im == 0.0) {
          if (s_im == 0.0) {
            R->data[i + R->size[0] * j].re = T_re / R_re;
            R->data[i + R->size[0] * j].im = 0.0;
          } else if (T_re == 0.0) {
            R->data[i + R->size[0] * j].re = 0.0;
            R->data[i + R->size[0] * j].im = s_im / R_re;
          } else {
            R->data[i + R->size[0] * j].re = T_re / R_re;
            R->data[i + R->size[0] * j].im = s_im / R_re;
          }
        } else if (R_re == 0.0) {
          if (T_re == 0.0) {
            R->data[i + R->size[0] * j].re = s_im / R_im;
            R->data[i + R->size[0] * j].im = 0.0;
          } else if (s_im == 0.0) {
            R->data[i + R->size[0] * j].re = 0.0;
            R->data[i + R->size[0] * j].im = -(T_re / R_im);
          } else {
            R->data[i + R->size[0] * j].re = s_im / R_im;
            R->data[i + R->size[0] * j].im = -(T_re / R_im);
          }
        } else {
          s_re = fabs(R_re);
          bim = fabs(R_im);
          if (s_re > bim) {
            s_re = R_im / R_re;
            bim = R_re + s_re * R_im;
            R->data[i + R->size[0] * j].re = (T_re + s_re * s_im) / bim;
            R->data[i + R->size[0] * j].im = (s_im - s_re * T_re) / bim;
          } else if (bim == s_re) {
            if (R_re > 0.0) {
              R_re = 0.5;
            } else {
              R_re = -0.5;
            }

            if (R_im > 0.0) {
              bim = 0.5;
            } else {
              bim = -0.5;
            }

            R->data[i + R->size[0] * j].re = (T_re * R_re + s_im * bim) / s_re;
            R->data[i + R->size[0] * j].im = (s_im * R_re - T_re * bim) / s_re;
          } else {
            s_re = R_re / R_im;
            bim = R_im + s_re * R_re;
            R->data[i + R->size[0] * j].re = (s_re * T_re + s_im) / bim;
            R->data[i + R->size[0] * j].im = (s_re * s_im - T_re) / bim;
          }
        }
      }
    }
  }

  emxFree_creal_T(&T);
  emxInit_creal_T(&y, 2);
  if ((Q->size[1] == 1) || (R->size[0] == 1)) {
    i14 = y->size[0] * y->size[1];
    y->size[0] = Q->size[0];
    y->size[1] = R->size[1];
    emxEnsureCapacity((emxArray__common *)y, i14, sizeof(creal_T));
    br = Q->size[0];
    for (i14 = 0; i14 < br; i14++) {
      ar = R->size[1];
      for (i15 = 0; i15 < ar; i15++) {
        y->data[i14 + y->size[0] * i15].re = 0.0;
        y->data[i14 + y->size[0] * i15].im = 0.0;
        j = Q->size[1];
        for (i = 0; i < j; i++) {
          bim = Q->data[i14 + Q->size[0] * i].re * R->data[i + R->size[0] * i15]
            .re - Q->data[i14 + Q->size[0] * i].im * R->data[i + R->size[0] *
            i15].im;
          R_re = Q->data[i14 + Q->size[0] * i].re * R->data[i + R->size[0] * i15]
            .im + Q->data[i14 + Q->size[0] * i].im * R->data[i + R->size[0] *
            i15].re;
          y->data[i14 + y->size[0] * i15].re += bim;
          y->data[i14 + y->size[0] * i15].im += R_re;
        }
      }
    }
  } else {
    k = Q->size[1];
    uv0[0] = (unsigned int)Q->size[0];
    uv0[1] = (unsigned int)R->size[1];
    i14 = y->size[0] * y->size[1];
    y->size[0] = (int)uv0[0];
    y->size[1] = (int)uv0[1];
    emxEnsureCapacity((emxArray__common *)y, i14, sizeof(creal_T));
    m = Q->size[0];
    i14 = y->size[0] * y->size[1];
    emxEnsureCapacity((emxArray__common *)y, i14, sizeof(creal_T));
    br = y->size[1];
    for (i14 = 0; i14 < br; i14++) {
      ar = y->size[0];
      for (i15 = 0; i15 < ar; i15++) {
        y->data[i15 + y->size[0] * i14].re = 0.0;
        y->data[i15 + y->size[0] * i14].im = 0.0;
      }
    }

    if ((Q->size[0] == 0) || (R->size[1] == 0)) {
    } else {
      j = Q->size[0] * (R->size[1] - 1);
      i = 0;
      while ((m > 0) && (i <= j)) {
        i14 = i + m;
        for (ic = i; ic + 1 <= i14; ic++) {
          y->data[ic].re = 0.0;
          y->data[ic].im = 0.0;
        }

        i += m;
      }

      br = 0;
      i = 0;
      while ((m > 0) && (i <= j)) {
        ar = -1;
        i14 = br + k;
        for (ib = br; ib + 1 <= i14; ib++) {
          b_R = ((R->data[ib].re != 0.0) || (R->data[ib].im != 0.0));
          if (b_R) {
            s_re = R->data[ib].re - 0.0 * R->data[ib].im;
            s_im = R->data[ib].im + 0.0 * R->data[ib].re;
            ia = ar;
            i15 = i + m;
            for (ic = i; ic + 1 <= i15; ic++) {
              ia++;
              R_re = s_re * Q->data[ia].re - s_im * Q->data[ia].im;
              bim = s_re * Q->data[ia].im + s_im * Q->data[ia].re;
              y->data[ic].re += R_re;
              y->data[ic].im += bim;
            }
          }

          ar += m;
        }

        br += k;
        i += m;
      }
    }
  }

  emxFree_creal_T(&R);
  emxInit_creal_T(&b, 2);
  i14 = b->size[0] * b->size[1];
  b->size[0] = Q->size[1];
  b->size[1] = Q->size[0];
  emxEnsureCapacity((emxArray__common *)b, i14, sizeof(creal_T));
  br = Q->size[0];
  for (i14 = 0; i14 < br; i14++) {
    ar = Q->size[1];
    for (i15 = 0; i15 < ar; i15++) {
      b->data[i15 + b->size[0] * i14].re = Q->data[i14 + Q->size[0] * i15].re;
      b->data[i15 + b->size[0] * i14].im = -Q->data[i14 + Q->size[0] * i15].im;
    }
  }

  emxFree_creal_T(&Q);
  if ((y->size[1] == 1) || (b->size[0] == 1)) {
    i14 = X->size[0] * X->size[1];
    X->size[0] = y->size[0];
    X->size[1] = b->size[1];
    emxEnsureCapacity((emxArray__common *)X, i14, sizeof(creal_T));
    br = y->size[0];
    for (i14 = 0; i14 < br; i14++) {
      ar = b->size[1];
      for (i15 = 0; i15 < ar; i15++) {
        X->data[i14 + X->size[0] * i15].re = 0.0;
        X->data[i14 + X->size[0] * i15].im = 0.0;
        j = y->size[1];
        for (i = 0; i < j; i++) {
          bim = y->data[i14 + y->size[0] * i].re * b->data[i + b->size[0] * i15]
            .re - y->data[i14 + y->size[0] * i].im * b->data[i + b->size[0] *
            i15].im;
          R_re = y->data[i14 + y->size[0] * i].re * b->data[i + b->size[0] * i15]
            .im + y->data[i14 + y->size[0] * i].im * b->data[i + b->size[0] *
            i15].re;
          X->data[i14 + X->size[0] * i15].re += bim;
          X->data[i14 + X->size[0] * i15].im += R_re;
        }
      }
    }
  } else {
    k = y->size[1];
    uv0[0] = (unsigned int)y->size[0];
    uv0[1] = (unsigned int)b->size[1];
    i14 = X->size[0] * X->size[1];
    X->size[0] = (int)uv0[0];
    X->size[1] = (int)uv0[1];
    emxEnsureCapacity((emxArray__common *)X, i14, sizeof(creal_T));
    m = y->size[0];
    i14 = X->size[0] * X->size[1];
    emxEnsureCapacity((emxArray__common *)X, i14, sizeof(creal_T));
    br = X->size[1];
    for (i14 = 0; i14 < br; i14++) {
      ar = X->size[0];
      for (i15 = 0; i15 < ar; i15++) {
        X->data[i15 + X->size[0] * i14].re = 0.0;
        X->data[i15 + X->size[0] * i14].im = 0.0;
      }
    }

    if ((y->size[0] == 0) || (b->size[1] == 0)) {
    } else {
      j = y->size[0] * (b->size[1] - 1);
      i = 0;
      while ((m > 0) && (i <= j)) {
        i14 = i + m;
        for (ic = i; ic + 1 <= i14; ic++) {
          X->data[ic].re = 0.0;
          X->data[ic].im = 0.0;
        }

        i += m;
      }

      br = 0;
      i = 0;
      while ((m > 0) && (i <= j)) {
        ar = -1;
        i14 = br + k;
        for (ib = br; ib + 1 <= i14; ib++) {
          b_R = ((b->data[ib].re != 0.0) || (b->data[ib].im != 0.0));
          if (b_R) {
            s_re = b->data[ib].re - 0.0 * b->data[ib].im;
            s_im = b->data[ib].im + 0.0 * b->data[ib].re;
            ia = ar;
            i15 = i + m;
            for (ic = i; ic + 1 <= i15; ic++) {
              ia++;
              R_re = s_re * y->data[ia].re - s_im * y->data[ia].im;
              bim = s_re * y->data[ia].im + s_im * y->data[ia].re;
              X->data[ic].re += R_re;
              X->data[ic].im += bim;
            }
          }

          ar += m;
        }

        br += k;
        i += m;
      }
    }
  }

  emxFree_creal_T(&b);
  emxFree_creal_T(&y);
  if ((X->size[0] == 0) || (X->size[1] == 0)) {
    bim = 0.0;
  } else if ((X->size[0] == 1) || (X->size[1] == 1)) {
    bim = 0.0;
    i14 = X->size[0] * X->size[1];
    for (k = 0; k < i14; k++) {
      bim += rt_hypotd_snf(X->data[k].re, X->data[k].im);
    }
  } else {
    bim = 0.0;
    j = 0;
    exitg1 = false;
    while ((!exitg1) && (j <= X->size[1] - 1)) {
      s_re = 0.0;
      for (i = 0; i < X->size[0]; i++) {
        s_re += rt_hypotd_snf(X->data[i + X->size[0] * j].re, X->data[i +
                              X->size[0] * j].im);
      }

      if (rtIsNaN(s_re)) {
        bim = rtNaN;
        exitg1 = true;
      } else {
        if (s_re > bim) {
          bim = s_re;
        }

        j++;
      }
    }
  }

  emxInit_real_T1(&b_X, 2);
  i14 = b_X->size[0] * b_X->size[1];
  b_X->size[0] = X->size[0];
  b_X->size[1] = X->size[1];
  emxEnsureCapacity((emxArray__common *)b_X, i14, sizeof(double));
  br = X->size[0] * X->size[1];
  for (i14 = 0; i14 < br; i14++) {
    b_X->data[i14] = X->data[i14].im;
  }

  if (norm(b_X) <= 10.0 * (double)A->size[0] * 2.2204460492503131E-16 * bim) {
    for (j = 0; j + 1 <= n; j++) {
      for (i = 0; i + 1 <= n; i++) {
        bim = X->data[i + X->size[0] * j].re;
        X->data[i + X->size[0] * j].re = bim;
        X->data[i + X->size[0] * j].im = 0.0;
      }
    }
  }

  emxFree_real_T(&b_X);
}

/* End of code generation (sqrtm.c) */
