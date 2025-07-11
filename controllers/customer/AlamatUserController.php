<?php

namespace App\Http\Controllers\customer;

use App\Http\Controllers\Controller;
use App\Models\Alamat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AlamatUserController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function get_provinsi()
    {
        $curl = curl_init();

        curl_setopt_array($curl, array(
            CURLOPT_URL => "https://api.rajaongkir.com/starter/province",
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => "",
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => "GET",
            CURLOPT_HTTPHEADER => array(
                "key: f201c33f7b1021a48e2a76125bfa5e15"
            ),
        ));

        $response = curl_exec($curl);
        $err = curl_error($curl);

        curl_close($curl);

        if ($err) {
            return response()->json(['error' => $err], 500);
        } else {
            $response = json_decode($response, true);
            $provinsi = $response['rajaongkir']['results'];
            return response()->json($provinsi);
        }
    }

    public function get_city($provinsi_id = null)
    {
        $curl = curl_init();

        $url = "https://api.rajaongkir.com/starter/city";
        if ($provinsi_id) {
            $url .= "?province=" . $provinsi_id;
        }

        curl_setopt_array($curl, array(
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => "",
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => "GET",
            CURLOPT_HTTPHEADER => array(
                "key: f201c33f7b1021a48e2a76125bfa5e15"
            ),
        ));

        $response = curl_exec($curl);
        $err = curl_error($curl);

        curl_close($curl);

        if ($err) {
            return response()->json(['error' => $err], 500);
        } else {
            $response = json_decode($response, true);
            $city = $response['rajaongkir']['results'];
            return response()->json($city);
        }
    }

    public function index()
    {
        $provinsi = $this->get_provinsi();
        $city = $this->get_city();
        $alamat = Alamat::where('id_user', Auth::user()->id)->first();

        if ($alamat == NULL) {
            return to_route('alamat.create');
        }
        return view('customer.alamat.alamat', compact(['alamat','provinsi','city']));
    }

    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        $provinsi = $this->get_provinsi();
        $city = $this->get_city();

        $alamat = Alamat::where('id_user', Auth::user()->id)->first();

        if ($alamat == NULL) {
            return view('customer.alamat.alamat_create', compact(['provinsi','city']));
        }
        return to_route('alamat.index');
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $request->validate([
            'nama'=>'required',
            'kode_pos'=>'required',
            'telp'=>'required',
            'alamat'=>'required',
            'provinsi' => 'required',
            'kota' => 'required',
        ]);

        $provinsi = $request->provinsi;
        $provinsi_result = explode('|', $provinsi);
        $id_provinsi = $provinsi_result[0];
        $nama_provinsi = $provinsi_result[1];

        $kota = $request->kota;
        $kota_result = explode('|', $kota);
        $id_kota = $kota_result[0];
        $nama_kota = $kota_result[1];

        Alamat::create([
            'id_user' => Auth::user()->id,
            'no_telp' => $request->telp,
            'nama_penerima' => $request->nama,
            'id_provinsi' => $id_provinsi,
            'nama_prov' => $nama_provinsi,
            'id_kota' => $id_kota,
            'nama_kota' => $nama_kota,
            'kode_pos' => $request->kode_pos,
            'alamat_lengkap' => $request->alamat,

        ]);

        return to_route('alamat.index')->with('success', 'Berhasil Menambahkan Alamat Pengiriman');
    }

    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function edit($id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            'nama'=>'required',
            'kode_pos'=>'required',
            'telp'=>'required',
            'alamat'=>'required',
            'provinsi' => 'required',
            'kota' => 'required',
        ]);

        $provinsi = $request->provinsi;
        $provinsi_result = explode('|', $provinsi);
        $id_provinsi = $provinsi_result[0];
        $nama_provinsi = $provinsi_result[1];

        $kota = $request->kota;
        $kota_result = explode('|', $kota);
        $id_kota = $kota_result[0];
        $nama_kota = $kota_result[1];

        Alamat::find($id)->update([
            'id_user' => Auth::user()->id,
            'no_telp' => $request->telp,
            'nama_penerima' => $request->nama,
            'id_provinsi' => $id_provinsi,
            'nama_prov' => $nama_provinsi,
            'id_kota' => $id_kota,
            'nama_kota' => $nama_kota,
            'kode_pos' => $request->kode_pos,
            'alamat_lengkap' => $request->alamat,

        ]);
        return back()->with('success', 'Berhasil Memperbaharui Alamat Pengiriman');
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        //
    }

    public function saveAlamat(Request $request, $userId)
    {
        try {
            $request->validate([
                'nama_penerima' => 'required',
                'alamat' => 'required',
                'provinsi' => 'required',
                'kota' => 'required',
                'kodepos' => 'required',
                'telp' => 'required',
            ]);

            $provinsi = explode('|', $request->provinsi);
            $kota = explode('|', $request->kota);

            $alamat = Alamat::updateOrCreate(
                ['id_user' => $userId],
                [
                    'nama_penerima' => $request->nama_penerima,
                    'alamat_lengkap' => $request->alamat,
                    'id_provinsi' => $provinsi[0],
                    'nama_prov' => $provinsi[1],
                    'id_kota' => $kota[0],
                    'nama_kota' => $kota[1],
                    'kode_pos' => $request->kodepos,
                    'no_telp' => $request->telp,
                ]
            );

            return response()->json([
                'message' => 'Alamat berhasil disimpan',
                'data' => $alamat
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Gagal menyimpan alamat: ' . $e->getMessage()
            ], 500);
        }
    }
}
