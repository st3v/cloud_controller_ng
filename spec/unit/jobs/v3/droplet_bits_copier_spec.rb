require 'spec_helper'

module VCAP::CloudController
  module Jobs::V3
    describe DropletBitsCopier do
      subject(:job) { DropletBitsCopier.new(source_droplet.guid, destination_droplet.guid) }

      let(:droplet_bits_path) { File.expand_path('../../../fixtures/good.zip', File.dirname(__FILE__)) }
      let(:blobstore_dir) { Dir.mktmpdir }
      let(:droplet_blobstore) do
        CloudController::Blobstore::FogClient.new({ provider: 'Local', local_root: blobstore_dir }, 'droplet')
      end
      let(:source_droplet) { DropletModel.make(:buildpack, droplet_hash: 'abcdef1234') }
      let(:destination_droplet) { DropletModel.make(:buildpack, state: DropletModel::PENDING_STATE) }

      before do
        Fog.unmock!
      end

      after do
        Fog.mock!
        FileUtils.remove_entry_secure blobstore_dir
      end

      it { is_expected.to be_a_valid_job }

      it 'knows its job name' do
        expect(job.job_name_in_configuration).to equal(:droplet_bits_copier)
      end

      describe '#perform' do
        before do
          allow(CloudController::DependencyLocator.instance).to receive(:droplet_blobstore).and_return(droplet_blobstore)
          droplet_blobstore.cp_to_blobstore(droplet_bits_path, source_droplet.blobstore_key)
        end

        it 'copies the source droplet zip to the droplet blob store for the destination droplet' do
          expect(droplet_blobstore.exists?(destination_droplet.guid)).to be false

          job.perform

          expect(droplet_blobstore.exists?(destination_droplet.reload.blobstore_key)).to be true
        end

        it 'updates the destination droplet_hash and state' do
          expect(destination_droplet.droplet_hash).to be nil
          expect(destination_droplet.state).not_to eq(source_droplet.state)

          job.perform

          destination_droplet.reload
          expect(destination_droplet.droplet_hash).to eq(source_droplet.droplet_hash)
          expect(destination_droplet.state).to eq(source_droplet.state)
        end

        context 'when using bits-service' do
          let(:bits_client) { double(BitsClient) }
          let(:dest_droplet_guid) { 'some-droplet-guid' }

          before do
            allow(CloudController::DependencyLocator.instance).to receive(:bits_client).and_return(bits_client)
            allow(bits_client).to receive(:duplicate_droplet).and_return(dest_droplet_guid)
          end

          it 'does not call blobstore.cp' do
            expect(droplet_blobstore).not_to receive(:cp_file_between_keys)
            job.perform
          end

          it 'calls duplicate_droplet on bits_client' do
            expect(bits_client).to receive(:duplicate_droplet).with(source_droplet.droplet_hash)
            job.perform
          end

          it 'sets the droplet_hash for the destination droplet' do
            expect { job.perform }.to change { destination_droplet.refresh.droplet_hash }.to(dest_droplet_guid)
          end

          it 'sets the state for the destination droplet to READY' do
            expect { job.perform }.to change { destination_droplet.refresh.state }.to(VCAP::CloudController::DropletModel::STAGING_STATE)
          end

          context 'and duplicate_droplet fails' do
            let(:expected_error) { 'some-error' }

            before do
              allow(bits_client).to receive(:duplicate_droplet).and_raise(expected_error)
            end

            it 'sets the state for the destination droplet to FAILED' do
              expect { job.perform }.to raise_error(expected_error)
              expect(destination_droplet.refresh.state).to eq(VCAP::CloudController::DropletModel::FAILED_STATE)
              expect(destination_droplet.error).to eq("failed to copy - #{expected_error}")
            end
          end
        end

        context 'when the copy fails' do
          before do
            allow(droplet_blobstore).to receive(:cp_file_between_keys).and_raise('ba boom!')
          end

          it 'marks the droplet as failed and saves the message and raises the error' do
            expect(destination_droplet.error).to be nil

            expect { job.perform }.to raise_error('ba boom!')

            destination_droplet.reload
            expect(destination_droplet.error).to eq('failed to copy - ba boom!')
            expect(destination_droplet.state).to eq(VCAP::CloudController::DropletModel::FAILED_STATE)
          end
        end

        context 'when the source droplet does not exist' do
          before { source_droplet.destroy }

          it 'marks the droplet as failed and saves the message and raises the error' do
            expect(destination_droplet.error).to be nil

            expect { job.perform }.to raise_error('source droplet does not exist')

            destination_droplet.reload
            expect(destination_droplet.error).to eq('failed to copy - source droplet does not exist')
            expect(destination_droplet.state).to eq(VCAP::CloudController::DropletModel::FAILED_STATE)
          end
        end

        context 'when the destination droplet does not exist' do
          before { destination_droplet.destroy }

          it 'marks the droplet as failed and saves the message and raises the error' do
            expect { job.perform }.to raise_error('destination droplet does not exist')
          end
        end
      end
    end
  end
end
