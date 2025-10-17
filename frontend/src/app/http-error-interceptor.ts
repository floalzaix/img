import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

export const httpErrorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      console.error('Error:', error);

      switch (error.status) {
        case 415:
          router.navigate(['/error-415']);
          break;
        case 422:
          router.navigate(['/error-422']);
          break;
        default:
          router.navigate(['/error']);
          break;
      }

      return throwError(() => error);
    })
  );
};
