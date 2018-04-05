/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * mrdivide.c
 *
 * Code generation for function 'mrdivide'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "mrdivide.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"
#include "lusolve.h"
#include "xgeqp3.h"

/* Function Definitions */
void b_mrdivide(const emxArray_real_T *A, const emxArray_real32_T *B,
                emxArray_real32_T *y)
{
  emxArray_real32_T *Y;
  emxArray_real_T *b_B;
  emxArray_real32_T *b_A;
  emxArray_real32_T *tau;
  emxArray_int32_T *jpvt;
  unsigned int unnamed_idx_0;
  int m;
  unsigned int unnamed_idx_1;
  int loop_ub;
  int minmn;
  int maxmn;
  int rankR;
  float tol;
  int nb;
  int b_nb;
  int mn;
  emxInit_real32_T(&Y, 2);
  emxInit_real_T1(&b_B, 2);
  emxInit_real32_T(&b_A, 2);
  emxInit_real32_T1(&tau, 1);
  emxInit_int32_T1(&jpvt, 2);
  if ((A->size[0] == 0) || (A->size[1] == 0) || ((B->size[0] == 0) || (B->size[1]
        == 0))) {
    unnamed_idx_0 = (unsigned int)A->size[0];
    unnamed_idx_1 = (unsigned int)B->size[0];
    m = y->size[0] * y->size[1];
    y->size[0] = (int)unnamed_idx_0;
    y->size[1] = (int)unnamed_idx_1;
    emxEnsureCapacity((emxArray__common *)y, m, sizeof(float));
    loop_ub = (int)unnamed_idx_0 * (int)unnamed_idx_1;
    for (m = 0; m < loop_ub; m++) {
      y->data[m] = 0.0F;
    }
  } else if (B->size[0] == B->size[1]) {
    lusolve(B, A, y);
  } else {
    m = b_B->size[0] * b_B->size[1];
    b_B->size[0] = A->size[1];
    b_B->size[1] = A->size[0];
    emxEnsureCapacity((emxArray__common *)b_B, m, sizeof(double));
    loop_ub = A->size[0];
    for (m = 0; m < loop_ub; m++) {
      minmn = A->size[1];
      for (maxmn = 0; maxmn < minmn; maxmn++) {
        b_B->data[maxmn + b_B->size[0] * m] = A->data[m + A->size[0] * maxmn];
      }
    }

    m = b_A->size[0] * b_A->size[1];
    b_A->size[0] = B->size[1];
    b_A->size[1] = B->size[0];
    emxEnsureCapacity((emxArray__common *)b_A, m, sizeof(float));
    loop_ub = B->size[0];
    for (m = 0; m < loop_ub; m++) {
      minmn = B->size[1];
      for (maxmn = 0; maxmn < minmn; maxmn++) {
        b_A->data[maxmn + b_A->size[0] * m] = B->data[m + B->size[0] * maxmn];
      }
    }

    xgeqp3(b_A, tau, jpvt);
    rankR = 0;
    if (b_A->size[0] < b_A->size[1]) {
      minmn = b_A->size[0];
      maxmn = b_A->size[1];
    } else {
      minmn = b_A->size[1];
      maxmn = b_A->size[0];
    }

    if (minmn > 0) {
      tol = (float)maxmn * (float)fabs(b_A->data[0]) * 1.1920929E-7F;
      while ((rankR < minmn) && ((float)fabs(b_A->data[rankR + b_A->size[0] *
               rankR]) >= tol)) {
        rankR++;
      }
    }

    nb = b_B->size[1];
    minmn = b_A->size[1];
    maxmn = b_B->size[1];
    m = Y->size[0] * Y->size[1];
    Y->size[0] = minmn;
    Y->size[1] = maxmn;
    emxEnsureCapacity((emxArray__common *)Y, m, sizeof(float));
    loop_ub = minmn * maxmn;
    for (m = 0; m < loop_ub; m++) {
      Y->data[m] = 0.0F;
    }

    m = b_A->size[0];
    b_nb = b_B->size[1];
    minmn = b_A->size[0];
    mn = b_A->size[1];
    if (minmn < mn) {
      mn = minmn;
    }

    for (minmn = 0; minmn + 1 <= mn; minmn++) {
      if (tau->data[minmn] != 0.0F) {
        for (maxmn = 0; maxmn + 1 <= b_nb; maxmn++) {
          tol = (float)b_B->data[minmn + b_B->size[0] * maxmn];
          for (loop_ub = minmn + 1; loop_ub + 1 <= m; loop_ub++) {
            tol += b_A->data[loop_ub + b_A->size[0] * minmn] * (float)b_B->
              data[loop_ub + b_B->size[0] * maxmn];
          }

          tol *= tau->data[minmn];
          if (tol != 0.0F) {
            b_B->data[minmn + b_B->size[0] * maxmn] = (float)b_B->data[minmn +
              b_B->size[0] * maxmn] - tol;
            for (loop_ub = minmn + 1; loop_ub + 1 <= m; loop_ub++) {
              b_B->data[loop_ub + b_B->size[0] * maxmn] = (float)b_B->
                data[loop_ub + b_B->size[0] * maxmn] - b_A->data[loop_ub +
                b_A->size[0] * minmn] * tol;
            }
          }
        }
      }
    }

    for (maxmn = 0; maxmn + 1 <= nb; maxmn++) {
      for (loop_ub = 0; loop_ub + 1 <= rankR; loop_ub++) {
        Y->data[(jpvt->data[loop_ub] + Y->size[0] * maxmn) - 1] = (float)
          b_B->data[loop_ub + b_B->size[0] * maxmn];
      }

      for (minmn = rankR - 1; minmn + 1 > 0; minmn--) {
        Y->data[(jpvt->data[minmn] + Y->size[0] * maxmn) - 1] /= b_A->data[minmn
          + b_A->size[0] * minmn];
        for (loop_ub = 0; loop_ub + 1 <= minmn; loop_ub++) {
          Y->data[(jpvt->data[loop_ub] + Y->size[0] * maxmn) - 1] -= Y->data
            [(jpvt->data[minmn] + Y->size[0] * maxmn) - 1] * b_A->data[loop_ub +
            b_A->size[0] * minmn];
        }
      }
    }

    m = y->size[0] * y->size[1];
    y->size[0] = Y->size[1];
    y->size[1] = Y->size[0];
    emxEnsureCapacity((emxArray__common *)y, m, sizeof(float));
    loop_ub = Y->size[0];
    for (m = 0; m < loop_ub; m++) {
      minmn = Y->size[1];
      for (maxmn = 0; maxmn < minmn; maxmn++) {
        y->data[maxmn + y->size[0] * m] = Y->data[m + Y->size[0] * maxmn];
      }
    }
  }

  emxFree_int32_T(&jpvt);
  emxFree_real32_T(&tau);
  emxFree_real32_T(&b_A);
  emxFree_real_T(&b_B);
  emxFree_real32_T(&Y);
}

void mrdivide(const emxArray_real_T *A, const double B[4], emxArray_real_T *y)
{
  int ix;
  double b_A[4];
  signed char ipiv[2];
  int nb;
  int iy;
  int k;
  double temp;
  int jBcol;
  int jAcol;
  if (A->size[0] == 0) {
    ix = y->size[0] * y->size[1];
    y->size[0] = 0;
    y->size[1] = 2;
    emxEnsureCapacity((emxArray__common *)y, ix, sizeof(double));
  } else {
    for (ix = 0; ix < 4; ix++) {
      b_A[ix] = B[ix];
    }

    for (ix = 0; ix < 2; ix++) {
      ipiv[ix] = (signed char)(1 + ix);
    }

    ix = 0;
    if (fabs(B[1]) > fabs(B[0])) {
      ix = 1;
    }

    if (B[ix] != 0.0) {
      if (ix != 0) {
        ipiv[0] = 2;
        ix = 0;
        iy = 1;
        for (k = 0; k < 2; k++) {
          temp = b_A[ix];
          b_A[ix] = b_A[iy];
          b_A[iy] = temp;
          ix += 2;
          iy += 2;
        }
      }

      b_A[1] /= b_A[0];
    }

    if (b_A[2] != 0.0) {
      b_A[3] += b_A[1] * -b_A[2];
    }

    nb = A->size[0];
    ix = y->size[0] * y->size[1];
    y->size[0] = A->size[0];
    y->size[1] = 2;
    emxEnsureCapacity((emxArray__common *)y, ix, sizeof(double));
    iy = A->size[0] << 1;
    for (ix = 0; ix < iy; ix++) {
      y->data[ix] = A->data[ix];
    }

    for (iy = 0; iy < 2; iy++) {
      jBcol = nb * iy;
      jAcol = iy << 1;
      k = 1;
      while (k <= iy) {
        if (b_A[jAcol] != 0.0) {
          for (ix = 0; ix + 1 <= nb; ix++) {
            y->data[ix + jBcol] -= b_A[jAcol] * y->data[ix];
          }
        }

        k = 2;
      }

      temp = 1.0 / b_A[iy + jAcol];
      for (ix = 0; ix + 1 <= nb; ix++) {
        y->data[ix + jBcol] *= temp;
      }
    }

    for (iy = 1; iy >= 0; iy += -1) {
      jBcol = nb * iy;
      jAcol = (iy << 1) + 1;
      k = iy + 2;
      while (k < 3) {
        if (b_A[jAcol] != 0.0) {
          for (ix = 0; ix + 1 <= nb; ix++) {
            y->data[ix + jBcol] -= b_A[jAcol] * y->data[ix + nb];
          }
        }

        k = 3;
      }
    }

    if (ipiv[0] != 1) {
      for (ix = 0; ix + 1 <= nb; ix++) {
        temp = y->data[ix];
        y->data[ix] = y->data[ix + y->size[0]];
        y->data[ix + y->size[0]] = temp;
      }
    }
  }
}

/* End of code generation (mrdivide.c) */
