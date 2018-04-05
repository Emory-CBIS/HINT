/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * xgeqp3.c
 *
 * Code generation for function 'xgeqp3'
 *
 */

/* Include files */
#include "rt_nonfinite.h"
#include "UpdateThetaBetaAprx_LargeData.h"
#include "xgeqp3.h"
#include "xnrm2.h"
#include "xscal.h"
#include "ixamax.h"
#include "UpdateThetaBetaAprx_LargeData_emxutil.h"
#include "colon.h"

/* Function Declarations */
static float rt_hypotf_snf(float u0, float u1);

/* Function Definitions */
static float rt_hypotf_snf(float u0, float u1)
{
  float y;
  float a;
  float b;
  a = (float)fabs(u0);
  b = (float)fabs(u1);
  if (a < b) {
    a /= b;
    y = b * (float)sqrt(a * a + 1.0F);
  } else if (a > b) {
    b /= a;
    y = a * (float)sqrt(b * b + 1.0F);
  } else if (rtIsNaNF(b)) {
    y = b;
  } else {
    y = a * 1.41421354F;
  }

  return y;
}

void xgeqp3(emxArray_real32_T *A, emxArray_real32_T *tau, emxArray_int32_T *jpvt)
{
  int m;
  int n;
  int k;
  int mn;
  int i16;
  emxArray_real32_T *work;
  emxArray_real32_T *vn1;
  emxArray_real32_T *vn2;
  int iy;
  int i;
  int i_i;
  int nmi;
  int mmi;
  int pvt;
  int ix;
  float temp2;
  float absxk;
  float xnorm;
  int i_ip1;
  int lastv;
  int lastc;
  boolean_T exitg2;
  int exitg1;
  float t;
  m = A->size[0];
  n = A->size[1];
  k = A->size[0];
  mn = A->size[1];
  if (k < mn) {
    mn = k;
  }

  i16 = tau->size[0];
  tau->size[0] = mn;
  emxEnsureCapacity((emxArray__common *)tau, i16, sizeof(float));
  eml_signed_integer_colon(A->size[1], jpvt);
  if (!((A->size[0] == 0) || (A->size[1] == 0))) {
    emxInit_real32_T1(&work, 1);
    k = A->size[1];
    i16 = work->size[0];
    work->size[0] = k;
    emxEnsureCapacity((emxArray__common *)work, i16, sizeof(float));
    for (i16 = 0; i16 < k; i16++) {
      work->data[i16] = 0.0F;
    }

    emxInit_real32_T1(&vn1, 1);
    emxInit_real32_T1(&vn2, 1);
    k = A->size[1];
    i16 = vn1->size[0];
    vn1->size[0] = k;
    emxEnsureCapacity((emxArray__common *)vn1, i16, sizeof(float));
    i16 = vn2->size[0];
    vn2->size[0] = vn1->size[0];
    emxEnsureCapacity((emxArray__common *)vn2, i16, sizeof(float));
    k = 1;
    for (iy = 0; iy + 1 <= n; iy++) {
      vn1->data[iy] = xnrm2(m, A, k);
      vn2->data[iy] = vn1->data[iy];
      k += m;
    }

    for (i = 0; i + 1 <= mn; i++) {
      i_i = i + i * m;
      nmi = n - i;
      mmi = (m - i) - 1;
      k = ixamax(nmi, vn1, i + 1);
      pvt = (i + k) - 1;
      if (pvt + 1 != i + 1) {
        ix = m * pvt;
        iy = m * i;
        for (k = 1; k <= m; k++) {
          xnorm = A->data[ix];
          A->data[ix] = A->data[iy];
          A->data[iy] = xnorm;
          ix++;
          iy++;
        }

        k = jpvt->data[pvt];
        jpvt->data[pvt] = jpvt->data[i];
        jpvt->data[i] = k;
        vn1->data[pvt] = vn1->data[i];
        vn2->data[pvt] = vn2->data[i];
      }

      if (i + 1 < m) {
        temp2 = A->data[i_i];
        absxk = 0.0F;
        if (!(1 + mmi <= 0)) {
          xnorm = b_xnrm2(mmi, A, i_i + 2);
          if (xnorm != 0.0F) {
            xnorm = rt_hypotf_snf(A->data[i_i], xnorm);
            if (A->data[i_i] >= 0.0F) {
              xnorm = -xnorm;
            }

            if ((float)fabs(xnorm) < 9.86076132E-32F) {
              pvt = 0;
              do {
                pvt++;
                xscal(mmi, 1.01412048E+31F, A, i_i + 2);
                xnorm *= 1.01412048E+31F;
                temp2 *= 1.01412048E+31F;
              } while (!((float)fabs(xnorm) >= 9.86076132E-32F));

              xnorm = b_xnrm2(mmi, A, i_i + 2);
              xnorm = rt_hypotf_snf(temp2, xnorm);
              if (temp2 >= 0.0F) {
                xnorm = -xnorm;
              }

              absxk = (xnorm - temp2) / xnorm;
              xscal(mmi, 1.0F / (temp2 - xnorm), A, i_i + 2);
              for (k = 1; k <= pvt; k++) {
                xnorm *= 9.86076132E-32F;
              }

              temp2 = xnorm;
            } else {
              absxk = (xnorm - A->data[i_i]) / xnorm;
              temp2 = 1.0F / (A->data[i_i] - xnorm);
              xscal(mmi, temp2, A, i_i + 2);
              temp2 = xnorm;
            }
          }
        }

        tau->data[i] = absxk;
        A->data[i_i] = temp2;
      } else {
        tau->data[i] = 0.0F;
      }

      if (i + 1 < n) {
        temp2 = A->data[i_i];
        A->data[i_i] = 1.0F;
        i_ip1 = (i + (i + 1) * m) + 1;
        if (tau->data[i] != 0.0F) {
          lastv = mmi + 1;
          k = i_i + mmi;
          while ((lastv > 0) && (A->data[k] == 0.0F)) {
            lastv--;
            k--;
          }

          lastc = nmi - 1;
          exitg2 = false;
          while ((!exitg2) && (lastc > 0)) {
            k = i_ip1 + (lastc - 1) * m;
            nmi = k;
            do {
              exitg1 = 0;
              if (nmi <= (k + lastv) - 1) {
                if (A->data[nmi - 1] != 0.0F) {
                  exitg1 = 1;
                } else {
                  nmi++;
                }
              } else {
                lastc--;
                exitg1 = 2;
              }
            } while (exitg1 == 0);

            if (exitg1 == 1) {
              exitg2 = true;
            }
          }
        } else {
          lastv = 0;
          lastc = 0;
        }

        if (lastv > 0) {
          if (lastc != 0) {
            for (iy = 1; iy <= lastc; iy++) {
              work->data[iy - 1] = 0.0F;
            }

            iy = 0;
            i16 = i_ip1 + m * (lastc - 1);
            pvt = i_ip1;
            while ((m > 0) && (pvt <= i16)) {
              ix = i_i;
              xnorm = 0.0F;
              k = (pvt + lastv) - 1;
              for (nmi = pvt; nmi <= k; nmi++) {
                xnorm += A->data[nmi - 1] * A->data[ix];
                ix++;
              }

              work->data[iy] += xnorm;
              iy++;
              pvt += m;
            }
          }

          if (!(-tau->data[i] == 0.0F)) {
            pvt = i_ip1 - 1;
            k = 0;
            for (iy = 1; iy <= lastc; iy++) {
              if (work->data[k] != 0.0F) {
                xnorm = work->data[k] * -tau->data[i];
                ix = i_i;
                i16 = lastv + pvt;
                for (nmi = pvt; nmi + 1 <= i16; nmi++) {
                  A->data[nmi] += A->data[ix] * xnorm;
                  ix++;
                }
              }

              k++;
              pvt += m;
            }
          }
        }

        A->data[i_i] = temp2;
      }

      for (iy = i + 1; iy + 1 <= n; iy++) {
        k = (i + m * iy) + 1;
        if (vn1->data[iy] != 0.0F) {
          xnorm = (float)fabs(A->data[i + A->size[0] * iy]) / vn1->data[iy];
          xnorm = 1.0F - xnorm * xnorm;
          if (xnorm < 0.0F) {
            xnorm = 0.0F;
          }

          temp2 = vn1->data[iy] / vn2->data[iy];
          temp2 = xnorm * (temp2 * temp2);
          if (temp2 <= 0.000345266977F) {
            if (i + 1 < m) {
              temp2 = 0.0F;
              if (!(mmi < 1)) {
                if (mmi == 1) {
                  temp2 = (float)fabs(A->data[k]);
                } else {
                  xnorm = 1.17549435E-38F;
                  pvt = k + mmi;
                  while (k + 1 <= pvt) {
                    absxk = (float)fabs(A->data[k]);
                    if (absxk > xnorm) {
                      t = xnorm / absxk;
                      temp2 = 1.0F + temp2 * t * t;
                      xnorm = absxk;
                    } else {
                      t = absxk / xnorm;
                      temp2 += t * t;
                    }

                    k++;
                  }

                  temp2 = xnorm * (float)sqrt(temp2);
                }
              }

              vn1->data[iy] = temp2;
              vn2->data[iy] = vn1->data[iy];
            } else {
              vn1->data[iy] = 0.0F;
              vn2->data[iy] = 0.0F;
            }
          } else {
            vn1->data[iy] *= (float)sqrt(xnorm);
          }
        }
      }
    }

    emxFree_real32_T(&vn2);
    emxFree_real32_T(&vn1);
    emxFree_real32_T(&work);
  }
}

/* End of code generation (xgeqp3.c) */
