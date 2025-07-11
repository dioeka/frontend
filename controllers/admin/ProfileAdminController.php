<?php

namespace App\Http\Controllers\admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class ProfileAdminController extends Controller
{
    public function index()
    {
        return view('admin.profile.profile');
    }

    public function update_foto(Request $request, $id)
    {
        if ($request->hasFile('img1')) {
            $foto_profile = $request->file('img1')->getClientOriginalName();
            $request->img1->move(public_path('foto_profile'), $foto_profile);
        }

        User::find($id)->update([
            'foto_profile' => $foto_profile
        ]);

        return back()->with('success', 'Berhasil Memperbaharui Foto Profile');
    }

    public function update_data(Request $request, $id)
    {
        $request->validate([
            'nama' => 'required',
            'email' => 'email|required',
            'telp' => 'required'
        ]);

        User::find($id)->update([
            'name' => $request->nama,
            'email' => $request->email,
            'hp' => $request->telp,
        ]);

        return back()->with('success', 'Berhasil Memperbaharui Profile');
    }

    public function update_password(Request $request, $id)
    {
        $request->validate([
            'password' => 'required|min:6',
            'repassword' => 'required|min:6|same:password'
        ]);

        User::find($id)->update([
            'password' => Hash::make($request->password)
        ]);

        return back()->with('success', 'Berhasil Memperbaharui Password Akun');
    }

    public function getProfileApi($id)
    {
        try {
            $user = User::find($id);
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'User tidak ditemukan'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'name' => $user->name,
                    'email' => $user->email,
                    'hp' => $user->hp,
                    'foto_profile' => $user->foto_profile
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage()
            ], 500);
        }
    }

    public function update_fotoApi(Request $request, $id)
    {
        try {
            if (!$request->hasFile('foto_profile')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Foto profile tidak ditemukan'
                ], 400);
            }

            $file = $request->file('foto_profile');
            $fileName = time() . '_' . $file->getClientOriginalName();
            $file->move(public_path('foto_profile'), $fileName);

            $user = User::find($id);
            if ($user->foto_profile) {
                $oldFile = public_path('foto_profile/' . $user->foto_profile);
                if (file_exists($oldFile)) {
                    unlink($oldFile);
                }
            }

            $user->update([
                'foto_profile' => $fileName
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Berhasil mengupdate foto profile',
                'data' => [
                    'foto_profile' => $fileName
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage()
            ], 500);
        }
    }

    public function update_dataApi(Request $request, $id)
    {
        try {
            $request->validate([
                'nama' => 'required',
                'email' => 'email|required',
                'telp' => 'required'
            ]);

            $user = User::find($id);
            $user->update([
                'name' => $request->nama,
                'email' => $request->email,
                'hp' => $request->telp,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Berhasil mengupdate profile',
                'data' => [
                    'name' => $user->name,
                    'email' => $user->email,
                    'hp' => $user->hp
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage()
            ], 500);
        }
    }

    public function update_passwordApi(Request $request, $id)
    {
        try {
            $request->validate([
                'password' => 'required|min:6',
                'repassword' => 'required|min:6|same:password'
            ]);

            $user = User::find($id);
            $user->update([
                'password' => Hash::make($request->password)
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Berhasil mengupdate password'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan: ' . $e->getMessage()
            ], 500);
        }
    }
}
