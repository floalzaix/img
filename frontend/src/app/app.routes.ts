import { Routes } from '@angular/router';
import { Page } from './features/watermark/components/page/page';
import { Error422 } from './features/errors/error-422/error-422';
import { Error } from './features/errors/error/error';
import { Error415 } from './features/errors/error-415/error-415';

export const routes: Routes = [
  {path: "home", component: Page},
  {path: "error-422", component: Error422},
  {path: "error-415", component: Error415},
  {path: "error", component: Error},
  {path: "**", redirectTo: "home"}
];
