import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class AppHttpClient {
  private readonly apiUrl = environment.apiUrl;

  constructor(private readonly http: HttpClient) {}

  // Requête POST
  post(endpoint: string, payload: any): Observable<Blob> {
    return this.http.post(this.apiUrl + endpoint, payload, { responseType: 'blob' });
  }
}
