// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable } from '@angular/core';
import {
  catchError,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ID } from '@datorama/akita';
import { HttpClient } from '@angular/common/http';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ProjectsQuery } from 'core-app/core/state/projects/projects.query';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  collectionKey,
  insertCollectionIntoState,
} from 'core-app/core/state/collection-store';
import { ProjectsStore } from './projects.store';
import { IProject } from './project.model';

@Injectable()
export class ProjectsResourceService {
  protected store = new ProjectsStore();

  readonly query = new ProjectsQuery(this.store);

  private get projectsPath():string {
    return this
      .apiV3Service
      .projects
      .path;
  }

  constructor(
    private http:HttpClient,
    private apiV3Service:ApiV3Service,
    private toastService:ToastService,
  ) {
  }

  fetchProjects(params:ApiV3ListParameters):Observable<IHALCollection<IProject>> {
    const collectionURL = collectionKey(params);

    return this
      .http
      .get<IHALCollection<IProject>>(this.projectsPath + collectionURL)
      .pipe(
        tap((collection) => insertCollectionIntoState(this.store, collection, collectionURL)),
        catchError((error) => {
          this.toastService.addError(error);
          throw error;
        }),
      );
  }

  lookup(id:ID, require = false):Observable<IProject|undefined> {
    if (require && !this.query.hasEntity(id)) {
      return this.http
        .get<IProject>(`${this.projectsPath}/${id}`)
        .pipe(
          tap((project) => {
            if (project) {
              this.store.add(project);
            }
          }),
        );
    }

    return this.query.selectEntity(id);
  }

  update(id:ID, project:Partial<IProject>):void {
    this.store.update(id, project);
  }
}
