import { Component } from '@angular/core';
import { UploadZone } from "../upload-zone/upload-zone";
import { DownloadZone } from '../../download-zone/download-zone';

@Component({
  selector: 'app-page',
  imports: [UploadZone, DownloadZone],
  templateUrl: './page.html',
  styleUrl: './page.css'
})
export class Page {

}
