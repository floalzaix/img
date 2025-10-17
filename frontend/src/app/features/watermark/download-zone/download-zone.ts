import { Component, inject, signal } from '@angular/core';
import { MatIcon } from '@angular/material/icon';
import { MatSpinner } from '@angular/material/progress-spinner';
import { WatermarkService } from '../watermark.service';

@Component({
  selector: 'app-download-zone',
  imports: [MatIcon, MatSpinner],
  templateUrl: './download-zone.html',
  styleUrl: './download-zone.css'
})
export class DownloadZone {
  //
  //   Fields
  //
  public readonly watermarkService = inject(WatermarkService);
  public isLoading = signal(false);

  //
  //   Methods
  //

  /**
   * Downloads the watermarked image
   */
  public download() {
    this.isLoading.set(true);
    this.watermarkService.watermark().subscribe({
      next: (response) => {
        const url = URL.createObjectURL(response);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'watermarked.png';
        a.click();
        URL.revokeObjectURL(url);
        this.isLoading.set(false);
      }});
  }

}
