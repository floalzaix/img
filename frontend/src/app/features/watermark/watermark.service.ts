import { inject, Injectable, signal } from '@angular/core';
import { AppHttpClient } from '../../core/services/http-client.service';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class WatermarkService {
  //
  //   Fields
  //
  public readonly client = inject(AppHttpClient);
  public readonly photoFile = signal<File | null>(null);
  public readonly watermarkFile = signal<File | null>(null);

  //
  //   Constructor
  //

  watermark(): Observable<Blob> {
    // Getting the request and checking for null
    const photoFile = this.photoFile();
    const watermarkFile = this.watermarkFile();
    if (!photoFile || !watermarkFile) {
      throw new Error(
        "Photo or watermark file is not set cannot watermark !"
      );
    }

    // Prepare the form data to send to the API
    const formData = new FormData();
    formData.append("photo", photoFile);
    formData.append("watermark", watermarkFile);

    // Send the request to the API
    return this.client.post("/watermark", formData);
  }
}
