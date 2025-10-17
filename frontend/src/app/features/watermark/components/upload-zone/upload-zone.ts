import { Component, inject, Input, signal } from '@angular/core';
import {
  FileSystemFileEntry,
  NgxFileDropEntry,
  NgxFileDropModule,
} from 'ngx-file-drop';
import { WatermarkService } from '../../watermark.service';
import { MatIconModule } from '@angular/material/icon';
import heic2any from 'heic2any';

@Component({
  selector: 'app-upload-zone',
  imports: [NgxFileDropModule, MatIconModule],
  templateUrl: './upload-zone.html',
  styleUrl: './upload-zone.css'
})
export class UploadZone {
  //
  //   Interfaces
  //

  @Input({ required: true }) type!: string;

  //
  //   Fields
  //
  public readonly watermarkService = inject(WatermarkService);
  public readonly file =  signal<Blob | null>(null);
  public readonly filePreview =  signal<string | null>(null);
  public readonly error =  signal<string | null>(null);

  //
  //   Methods
  //

  /**
   * Handles the file drop/click event
   * @param files The given files by the user
   */
  public onFileDrop(files: NgxFileDropEntry[]) {
    // Checking if only one file is dropped
    if (files.length !== 1) {
      this.error.set("Seulement un fichier peut être déposé à la fois !");
      return;
    }

    const ngxFile = files[0];

    // Checking if the file is a file and not a directory
    if (!ngxFile.fileEntry.isFile) {
      throw new Error("File is not a valid file !");
    }

    // Getting the file from the file entry
    const fileEntry = ngxFile.fileEntry as FileSystemFileEntry;
    fileEntry.file(async (f: File) => {
      if (f.type === 'image/heic' || f.name.endsWith('.heic')) {
        try {
          const newBlob= await heic2any({
            blob: f,
            toType: 'image/jpeg',
            quality: 0.9,
          });

          f = new File([newBlob as Blob],f.name.replace(/\.heic$/i, '.jpg'), {
            type: 'image/jpeg',
            lastModified: f.lastModified,
          })
        } catch (err) {
          console.error(err);
          this.error.set("Le fichier n'a pas été chargé correctement !");
          return;
        }
      }

      this.file.set(f);

      // Setting the file to the watermark service
      if (this.type == "photo") {
        this.watermarkService.photoFile.set(f);
      } else if (this.type == "watermark") {
        this.watermarkService.watermarkFile.set(f);
      }

      // Converting the file to a base64 string for preview
      const reader = new FileReader();
      reader.onload = () => {
        this.filePreview.set(reader.result as string);
      };
      const readFile = this.file();
      if (!readFile) {
        this.error.set("Le fichier n'a pas été chargé correctement !");
        return;
      }
      reader.readAsDataURL(readFile);

      this.error.set(null);
    });
  }
}
