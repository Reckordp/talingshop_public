class Barang
	attr_reader :id, :nama, :jumlah, :harga
	def initialize(id, nama, jumlah, harga)
		@id = id
		@nama = nama
		@jumlah = jumlah
		@harga = harga
	end
end

module Rupiah
	def self.nilai(puluhribu)
		sprintf("Rp #{puluhribu * 10_000},-")
	end
end

class ApplicationController < ActionController::Base
	ADMIN = "Reckordp"
	BARANG_RAW = {
		"Jenis Satu" => [1029, Rupiah.nilai(2)], 
		"Jenis Dua" => [47, Rupiah.nilai(50)], 
		"Jenis Tiga" => [761, Rupiah.nilai(7)], 
		"Jenis Empat" => [26, Rupiah.nilai(200)]
	}

	def index
		@admin = params.include?(:admin)
		@barang = []
		id = 0
		BARANG_RAW.each do |i, v|
			@barang.push(Barang.new(id, i, *v))
			id += 1
		end
	end

	def order
		id = params.require(:barang_id).to_i
		i = 0
		BARANG_RAW.each do |k, v|
			@barang = Barang.new(id, k, *v) if i == id
			i += 1
		end
	end

	def cari
		if cari_admin?(params)
			redirect_to action: :index, admin: "LOL"
		end

		@hasil = BARANG_RAW.select { |i, v| i.downcase =~ /#{nama_barang(params).downcase}/ } .collect do |i, v|
			Barang.new(BARANG_RAW.keys.index(i), i, *v)
		end
	end

	def kirim_orderan
		nama_barang = BARANG_RAW.keys[params.require(:barang_id).to_i]
		params[:pembeli][:barang] = nama_barang
		data = params.require(:pembeli).permit(:jumlah_order, :nama_pengorder, :wilayah, :alamat, :barang)
		BARANG_RAW[nama_barang][0] -= data[:jumlah_order].to_i
		proses_simpan_data(data)
		redirect_to action: :index
	end

	def penyimpanan
		$drop.download("/OrderTS") do |konten|
			send_data(konten, {filename: "OrderTS"})
		end
	end

	def pembuat_socket
		web_info = params.permit(:host, :port)
		if request.method == "POST" && !web_info.empty?
			hasil = 'Yay'
			begin
				TCPSocket.new(web_info[:host], web_info[:port].to_i).close
			rescue SocketError, Errno::ECONNREFUSED
				hasil = 'Nay'
			end
			render html: "<div align='center'><p>#{hasil}</p></div>".html_safe
		end
	end

	private
	def nama_barang(param)
		nama = param.require(:pencarian).permit(:barang)
		nama[:barang]
	end

	def cari_admin?(param)
		nama_barang(param) == ADMIN
	end

	def proses_simpan_data(data)
		data[:nama_pengorder].gsub!(/\!/, "")
		data[:nama_pengorder] = "- Kosong -" if data[:nama_pengorder].empty?
		data[:alamat] = "- Kosong -" if data[:alamat].empty?
		data[:alamat].gsub!(/\n/, "")
		simpan = sprintf("(%s!%s!%s!%s!%s)", 
			data[:barang], data[:jumlah_order], data[:nama_pengorder], data[:wilayah], data[:alamat])
		# Menyimpan ke API Cloud
		$drop.download("/OrderTS") do |konten|
			$drop.upload("/OrderTS", konten + simpan, { mode: :overwrite })
		end
	end
end
