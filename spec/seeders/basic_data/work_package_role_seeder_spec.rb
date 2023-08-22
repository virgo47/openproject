# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

RSpec.describe BasicData::WorkPackageRoleSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { Source::SeedData.new(data_hash) }

  before do
    seeder.seed!
  end

  context 'with some work package roles defined' do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        work_package_roles:
          - reference: :role_work_package_edit
            name: Edit work package
            position: 3
            permissions:
            - :become_assignee
            - :log_time
          - reference: :role_work_package_comment
            name: Comment work package
            position: 5
            permissions:
            - :add_comment
      SEEDING_DATA_YAML
    end

    it 'creates the corresponding work package roles with the given attributes' do
      expect(WorkPackageRole.count)
        .to eq(2)
      expect(WorkPackageRole.find_by(name: 'Edit work package'))
        .to have_attributes(
          builtin: Role::NON_BUILTIN,
          permissions: %i[become_assignee log_time]
        )
      expect(WorkPackageRole.find_by(name: 'Comment work package'))
        .to have_attributes(
          builtin: Role::NON_BUILTIN,
          permissions: %i[add_comment]
        )
    end

    it 'references the role in the seed data' do
      role = WorkPackageRole.find_by(name: 'Comment work package')
      expect(seed_data.find_reference(:role_work_package_comment)).to eq(role)
    end
  end

  context 'with permissions: :all_assignable_permissions',
          pending: 'Defining what `all_assignable_permissions` are for ' \
                   'the `WorkPackageRole` type is still a TODO' do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        work_package_roles:
          - reference: :role_work_package_edit
            name: Edit work package
            permissions: :all_assignable_permissions
      SEEDING_DATA_YAML
    end

    it 'gives all assignable permissions to the role' do
      expect(Roles::CreateContract.new(WorkPackageRole.new, nil)
                                  .assignable_permissions.map { _1.name.to_sym })
        .not_to match_array(Roles::CreateContract.new(Role.new, nil)
                                       .assignable_permissions.map { _1.name.to_sym })

      expect(Role.find_by(name: 'Edit work package').permissions)
        .to match_array(Roles::CreateContract.new(WorkPackageRole.new, nil)
                                             .assignable_permissions.map { _1.name.to_sym })
    end
  end

  context 'with some permissions added and removed by modules in a modules_permissions section' do
    let(:data_hash) do
      YAML.load <<~SEEDING_DATA_YAML
        work_package_roles:
          - reference: :role_work_package_edit
            name: Edit work package
            position: 5
            permissions:
            - :view_movies
            - :eat_cheese
        modules_permissions:
          ebooks:
          - role: :role_work_package_edit
            add:
            - :read_ebooks
            - :rate_ebooks
          music:
          - role: :role_work_package_edit
            add:
            - :play_music
            - :add_song
          health_control:
          - role: :role_work_package_edit
            remove:
            - :eat_cheese
      SEEDING_DATA_YAML
    end

    it 'applies the permissions as specified' do
      expect(Role.find_by(name: 'Edit work package').permissions)
        .to match_array(
          %i[
            view_movies
            read_ebooks
            rate_ebooks
            play_music
            add_song
          ]
        )
    end
  end
end
